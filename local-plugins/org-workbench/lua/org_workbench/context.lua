local headers = require("org_workbench.headers")
local M = {}

function M.arguments(doc, block, config)
	local args = headers.parse(config.default_header_args or ":results output replace")
	local language = (block.language or ""):lower()
	local function property(key, value)
		local plain = key:gsub("%+$", "")
		if plain == "header-args" or plain == "header-args:" .. language then
			headers.merge(args, headers.parse(value))
		end
	end
	local file_properties = {}
	for _, entry in ipairs(doc.file_headers) do
		local key = entry.key:gsub("%+$", "")
		file_properties[key] = entry.key:sub(-1) == "+" and ((file_properties[key] or "") .. " " .. entry.value)
			or entry.value
	end
	for _, key in ipairs({ "header-args", "header-args:" .. language }) do
		if file_properties[key] then
			property(key, file_properties[key])
		end
	end
	local ancestors, h = {}, block.heading
	while h do
		table.insert(ancestors, 1, h)
		h = h.parent
	end
	for _, ancestor in ipairs(ancestors) do
		-- Generic settings precede language-specific properties in the same drawer.
		for _, key in ipairs({
			"header-args",
			"header-args+",
			"header-args:" .. language,
			"header-args:" .. language .. "+",
		}) do
			if ancestor.properties[key] then
				property(key, ancestor.properties[key])
			end
		end
	end
	for _, line in ipairs(block.headers or {}) do
		headers.merge(args, headers.parse(line))
	end
	headers.merge(args, headers.parse(block.args))
	return args
end

function M.body(doc, block)
	local body = vim.list_slice(doc.lines, block.start_line + 1, block.end_line - 1)
	local margin
	for _, line in ipairs(body) do
		if line:find("%S") then
			local indent = line:match("^[ \t]*")
			margin = margin or indent
			while indent:sub(1, #margin) ~= margin do
				margin = margin:sub(1, -2)
			end
		end
	end
	if margin and margin ~= "" then
		for i, line in ipairs(body) do
			body[i] = line:find("%S") and line:sub(#margin + 1) or ""
		end
	end
	return table.concat(body, "\n")
end

function M.expand(doc, block, config, stack, resolved, dependencies)
	stack = stack or {}
	dependencies = dependencies or {}
	assert(not stack[block.start_line], "Referência noweb circular")
	stack[block.start_line] = true
	local body = M.body(doc, block)
	local args = M.arguments(doc, block, config)
	local sep = headers.get(args, "noweb-sep", "\n")
	body = body:gsub("([ \t]*)<<([^>\n]+)>>", function(indent, name)
		local reference, arguments = name:match("^([^%(]+)%((.*)%)$")
		if reference then
			local target = doc.named[reference]
			assert(target and target.kind == "src", "Bloco noweb não encontrado: " .. reference)
			if resolved and resolved[name] ~= nil then
				local value = resolved[name]
				local text = type(value) == "table" and vim.json.encode(value)
					or value == vim.NIL and ""
					or tostring(value)
				return indent .. text:gsub("\n", "\n" .. indent)
			end
			dependencies[#dependencies + 1] = { key = name, target = target, arguments = arguments }
			return indent .. "<<" .. name .. ">>"
		end
		local targets = {}
		if doc.named[name] then
			targets = { doc.named[name] }
		else
			for _, candidate in ipairs(doc.blocks) do
				if headers.get(M.arguments(doc, candidate, config), "noweb-ref") == name then
					targets[#targets + 1] = candidate
				end
			end
		end
		assert(#targets > 0, "Bloco noweb não encontrado: " .. name)
		local pieces = {}
		for _, target in ipairs(targets) do
			assert(target.kind == "src" and target.closed, "Referência noweb precisa de bloco src completo")
			pieces[#pieces + 1] = M.expand(doc, target, config, stack, resolved, dependencies)
		end
		return indent .. table.concat(pieces, sep):gsub("\n", "\n" .. indent)
	end)
	stack[block.start_line] = nil
	return body, dependencies
end

local function scalar(text)
	if text:sub(1, 1) == '"' or text:sub(1, 1) == "'" then
		return headers.unquote(text)
	end
	if tonumber(text) then
		return tonumber(text)
	end
	if text == "true" then
		return true
	elseif text == "false" then
		return false
	end
	if text == "nil" or text == "null" then
		return vim.NIL
	end
	return nil
end

function M.variables(doc, args, resolved)
	local variables, dependencies, metadata = {}, {}, {}
	for _, entry in ipairs(args.var or {}) do
		local name, text = entry:match("^([%a_][%w_]*)=(.+)$")
		assert(name, "Use :var nome=valor")
		local value = scalar(text)
		if value == nil and (text:sub(1, 1) == "[" or text:sub(1, 1) == "{") then
			local ok, decoded = pcall(vim.json.decode, text)
			assert(ok, "Lista/dicionário deve usar JSON válido")
			value = decoded
		end
		if value == nil then
			local reference, arguments = text:match("^([^%(]+)%((.*)%)$")
			local target = doc.named[reference or text]
			assert(target, "Variável ou referência não encontrada: " .. text)
			if target.kind == "src" then
				if resolved and resolved[text] ~= nil then
					value = resolved[text]
				else
					dependencies[#dependencies + 1] = { key = text, target = target, arguments = arguments }
				end
			elseif target.kind == "table" then
				value = {}
				local colnames = headers.get(args, "colnames", "nil")
				local first_is_header = colnames == "yes"
					or (colnames ~= "no" and (doc.lines[target.start_line + 1] or ""):match("^%s*|[-+|]+|%s*$"))
				for row = target.start_line, #doc.lines do
					local line = doc.lines[row]
					if not line:match("^%s*|") then
						break
					end
					if not line:match("^%s*|[-+|]+|%s*$") then
						local cells = vim.split(line:gsub("^%s*|", ""):gsub("|%s*$", ""), "|", { plain = true })
						for i, cell in ipairs(cells) do
							cells[i] = tonumber(vim.trim(cell)) or vim.trim(cell)
						end
						if row == target.start_line and first_is_header then
							if colnames == "yes" then
								metadata.table_header = cells
							end
						else
							value[#value + 1] = cells
						end
					end
				end
			elseif target.kind == "example" then
				value = M.body(doc, target)
			else
				error("Referência não suportada em :var")
			end
		end
		variables[name] = value
	end
	return variables, dependencies, metadata
end

function M.call_arguments(text)
	local parts, start, quote, depth = {}, 1, nil, 0
	for i = 1, #text do
		local c = text:sub(i, i)
		if quote then
			if c == quote and text:sub(i - 1, i - 1) ~= "\\" then
				quote = nil
			end
		elseif c == '"' or c == "'" then
			quote = c
		elseif c == "(" or c == "[" or c == "{" then
			depth = depth + 1
		elseif c == ")" or c == "]" or c == "}" then
			depth = depth - 1
		elseif c == "," and depth == 0 then
			parts[#parts + 1], start = vim.trim(text:sub(start, i - 1)), i + 1
		end
	end
	if vim.trim(text:sub(start)) ~= "" then
		parts[#parts + 1] = vim.trim(text:sub(start))
	end
	return { var = parts }
end

return M
