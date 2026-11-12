local M = {}

local function lua_literal(value)
	if value == vim.NIL then
		return "nil"
	end
	if type(value) == "string" then
		return string.format("%q", value)
	end
	if type(value) ~= "table" then
		return tostring(value)
	end
	local items = {}
	for key, item in pairs(value) do
		items[#items + 1] = "[" .. lua_literal(key) .. "]=" .. lua_literal(item)
	end
	return "{" .. table.concat(items, ",") .. "}"
end

local function shell_literal(value)
	assert(type(value) ~= "table" and value ~= vim.NIL, "Variável shell precisa ser um valor escalar")
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function M.prepare(language, code, variables, mode, token)
	local prefix = {}
	for _, name in ipairs(vim.tbl_keys(variables)) do
		local value = variables[name]
		if language == "lua" then
			prefix[#prefix + 1] = "local " .. name .. "=" .. lua_literal(value)
		elseif language == "javascript" or language == "js" then
			prefix[#prefix + 1] = "var " .. name .. "=" .. vim.json.encode(value) .. ";"
		elseif language == "bash" or language == "sh" or language == "shell" then
			prefix[#prefix + 1] = name .. "=" .. shell_literal(value)
		else
			error("Variáveis ainda não suportadas para " .. language)
		end
	end
	code = table.concat(prefix, "\n") .. "\n" .. code
	if mode == "output" then
		return code
	end
	if language == "javascript" or language == "js" then
		return "const __org_value__=(function(){\n"
			.. code
			.. "\n})();\nprocess.stdout.write("
			.. vim.json.encode(token)
			.. "+JSON.stringify({value:__org_value__===undefined?null:__org_value__})+'\\n');"
	elseif language == "lua" then
		return [[
local function __org_json(v, seen)
  if v == nil then return 'null' end
  if type(v) == 'boolean' or type(v) == 'number' then return tostring(v) end
  if type(v) == 'string' then
    return '"' .. v:gsub('[%z\1-\31\\"]', function(c)
      if c == '"' then return '\\"' elseif c == '\\' then return '\\\\' end
      return string.format('\\u%04x', string.byte(c))
    end) .. '"'
  end
  if type(v) ~= 'table' then return __org_json(tostring(v)) end
  seen=seen or {}; assert(not seen[v], 'circular result'); seen[v]=true
  local out={}; for i=1,#v do out[i]=__org_json(v[i],seen) end; seen[v]=nil
  return '[' .. table.concat(out, ',') .. ']'
end
local __org_value__=(function()
]] .. code .. "\nend)()\nio.write(" .. string.format("%q", token) .. ",'{' .. '\"value\":' .. __org_json(__org_value__) .. '}\\n')"
	elseif language == "sh" or language == "shell" or language == "bash" then
		return code
	end
	error("Resultados value ainda não suportados para " .. language)
end

function M.decode(result, token, mode)
	if mode ~= "value" or result.code ~= 0 then
		return result
	end
	local value, output = nil, {}
	for line in (result.stdout or ""):gmatch("[^\n]+") do
		local pos = line:find(token, 1, true)
		if pos then
			local ok, decoded = pcall(vim.json.decode, line:sub(pos + #token))
			if ok then
				value = decoded.value
				if pos > 1 then
					output[#output + 1] = line:sub(1, pos - 1)
				end
			end
		else
			output[#output + 1] = line
		end
	end
	result.value = value == nil and vim.trim(result.stdout or "") or value
	result.stdout = table.concat(output, "\n")
	return result
end

return M
