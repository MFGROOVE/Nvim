local M = {}

-- Keep quotes and balanced expressions intact, including spaces in :var values.
function M.tokens(text)
	local result, start, quote, escaped, depth = {}, nil, nil, false, 0
	for i = 1, #text do
		local c = text:sub(i, i)
		if not start and not c:match("%s") then
			start = i
		end
		if quote then
			if escaped then
				escaped = false
			elseif c == "\\" then
				escaped = true
			elseif c == quote then
				quote = nil
			end
		elseif c == '"' or c == "'" then
			quote = c
		elseif c == "(" or c == "[" or c == "{" then
			depth = depth + 1
		elseif c == ")" or c == "]" or c == "}" then
			depth = depth - 1
			assert(depth >= 0, "Expressão inválida no cabeçalho")
		elseif c:match("%s") and depth == 0 and start then
			result[#result + 1], start = text:sub(start, i - 1), nil
		end
	end
	assert(not quote and depth == 0, "Aspas ou expressão não fechadas no cabeçalho")
	if start then
		result[#result + 1] = text:sub(start)
	end
	return result
end

function M.unquote(value)
	if value:sub(1, 1) == '"' then
		local ok, decoded = pcall(vim.json.decode, value)
		if ok and type(decoded) == "string" then
			return decoded
		end
	end
	if (value:sub(1, 1) == '"' and value:sub(-1) == '"') or (value:sub(1, 1) == "'" and value:sub(-1) == "'") then
		return value:sub(2, -2)
	end
	return value
end

function M.parse(text)
	local result, key = {}, nil
	for _, token in ipairs(M.tokens(text or "")) do
		if token:match("^:[%w_-]+$") then
			key = token:sub(2)
			if key ~= "var" or not result[key] then
				result[key] = {}
			end
		elseif key then
			result[key][#result[key] + 1] = token
		end
	end
	return result
end

function M.merge(target, source)
	for key, values in pairs(source) do
		if key == "results" then
			local classes = {}
			for group, names in pairs({
				collection = "output value",
				type = "table vector list scalar verbatim file",
				format = "raw code drawer html latex org pp link graphics",
				handling = "replace append prepend silent none",
			}) do
				for name in names:gmatch("%S+") do
					classes[name] = group
				end
			end
			local selected, order = {}, {}
			for _, list in ipairs({ target.results or {}, values }) do
				for _, option in ipairs(list) do
					local group = classes[option] or option
					if not selected[group] then
						order[#order + 1] = group
					end
					selected[group] = option
				end
			end
			target.results = {}
			for _, group in ipairs(order) do
				target.results[#target.results + 1] = selected[group]
			end
		elseif key == "var" then
			local by_name, order = {}, {}
			for _, entries in ipairs({ target.var or {}, values }) do
				for _, entry in ipairs(entries) do
					local name = assert(entry:match("^([%a_][%w_]*)="), "Use :var nome=valor")
					if not by_name[name] then
						order[#order + 1] = name
					end
					by_name[name] = entry
				end
			end
			target.var = {}
			for _, name in ipairs(order) do
				target.var[#target.var + 1] = by_name[name]
			end
		else
			target[key] = vim.deepcopy(values)
		end
	end
	return target
end

function M.get(args, key, default)
	return args[key] and args[key][1] and M.unquote(args[key][1]) or default
end

return M
