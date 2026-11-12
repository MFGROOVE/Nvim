local headers = require("org_workbench.headers")
local M = {}

function M.options(args)
	local options = {}
	for _, option in ipairs(args.results or {}) do
		options[option] = true
	end
	return options
end

function M.span(lines, after)
	local first = after
	while lines[first + 1] and lines[first + 1]:match("^%s*$") do
		first = first + 1
	end
	if not (lines[first + 1] or ""):lower():match("^%s*#%+results[%[:]") then
		return after, after
	end
	local last = first + 1
	local function line()
		return lines[last + 1] or ""
	end
	if line():lower():match("^%s*#%+begin_") then
		local kind = line():lower():match("^%s*#%+begin_(%S+)")
		last = last + 1
		while lines[last + 1] do
			last = last + 1
			if lines[last]:lower():match("^%s*#%+end_(%S+)%s*$") == kind then
				break
			end
		end
	elseif line():lower():match("^%s*:results:%s*$") then
		last = last + 1
		while lines[last + 1] do
			last = last + 1
			if lines[last]:lower():match("^%s*:end:%s*$") then
				break
			end
		end
	elseif line():match("^%s*|") then
		while lines[last + 1] and line():match("^%s*|") do
			last = last + 1
		end
	elseif line():match("^%s*: ") or line():match("^%s*:%s*$") then
		while lines[last + 1] and (line():match("^%s*: ") or line():match("^%s*:%s*$")) do
			last = last + 1
		end
	elseif line():match("^%s*%[%[file:") then
		last = last + 1
	elseif line():match("^%s*[-+] ") then
		while lines[last + 1] and line():match("^%s*[-+] ") do
			last = last + 1
		end
	else
		while
			lines[last + 1]
			and not line():match("^%s*$")
			and not line():match("^%*+ ")
			and not line():match("^%s*#%+")
		do
			last = last + 1
		end
	end
	return first, last
end

local function scalar(value)
	if value == vim.NIL or value == nil then
		return "None"
	end
	if type(value) == "boolean" then
		return value and "True" or "False"
	end
	if type(value) == "table" then
		return vim.json.encode(value)
	end
	return tostring(value)
end

local function table_lines(value, header)
	local rows, widths = {}, {}
	if type(value) ~= "table" then
		value = { { value } }
	elseif #value > 0 and type(value[1]) ~= "table" then
		value = { value }
	end
	value = vim.deepcopy(value)
	if header then
		table.insert(value, 1, header)
	end
	for _, row in ipairs(value) do
		local cells = {}
		for i, cell in ipairs(type(row) == "table" and row or { row }) do
			cells[i] = scalar(cell):gsub("|", "\\vert{}"):gsub("\n", " ")
			widths[i] = math.max(widths[i] or 0, vim.fn.strdisplaywidth(cells[i]))
		end
		rows[#rows + 1] = cells
	end
	local rendered = {}
	for row_index, row in ipairs(rows) do
		local cells = {}
		for i, width in ipairs(widths) do
			local cell = row[i] or ""
			-- Org right-aligns numeric cells and left-aligns text.
			local space = string.rep(" ", width - vim.fn.strdisplaywidth(cell))
			cells[i] = " " .. (tonumber(cell) and space .. cell or cell .. space) .. " "
		end
		rendered[#rendered + 1] = "|" .. table.concat(cells, "|") .. "|"
		if header and row_index == 1 then
			local separators = {}
			for i, width in ipairs(widths) do
				separators[i] = string.rep("-", width + 2)
			end
			rendered[#rendered + 1] = "|" .. table.concat(separators, "+") .. "|"
		end
	end
	return rendered
end

function M.render(job, result)
	local options = job.options
	local wrap = headers.get(job.args, "wrap")
	if job.args.wrap and not wrap then
		wrap = "results"
	end
	if wrap == "no" or wrap == "nil" then
		wrap = nil
	end
	local error_output = job.cancelled or result.code ~= 0
	local output = result.stdout or ""
	if not error_output and options.value then
		output = scalar(result.value)
	end
	if result.stderr and result.stderr ~= "" then
		output = output .. (output ~= "" and output:sub(-1) ~= "\n" and "\n" or "") .. result.stderr
	end
	if job.cancelled then
		output = output .. "\n[Execução cancelada]"
	elseif result.code == 124 then
		output = output .. "\n[Tempo limite excedido]"
	elseif result.code ~= 0 then
		output = output .. "\n[Processo terminou com código " .. result.code .. "]"
	end
	if #output > job.max_output_bytes then
		output = output:sub(1, job.max_output_bytes) .. "\n[Saída truncada]"
	end
	output = output:gsub("\r\n", "\n"):gsub("\n$", ""):gsub("%z", "\\0")
	job.output = output
	if (options.silent or options.none) and not error_output then
		return nil
	end
	local content
	if options.file and not error_output then
		local path = job.file or (options.value and scalar(result.value) or vim.trim(output))
		assert(path and path ~= "", "Use :file caminho para resultados em arquivo")
		if not options.link and not options.graphics then
			local full = vim.startswith(path, "/") and path or vim.fs.joinpath(job.cwd, path)
			full = vim.fn.fnamemodify(full, ":p")
			assert(full ~= vim.api.nvim_buf_get_name(job.buf), "Resultado não pode sobrescrever o documento Org")
			local buf = vim.fn.bufnr(full)
			assert(buf < 0 or not vim.bo[buf].modified, "Arquivo de resultado tem alterações não salvas")
			vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
			vim.fn.writefile(vim.split(output, "\n", { plain = true }), full)
		end
		content = { "[[file:" .. path .. "]]" }
	elseif
		not error_output
		and (
			(
				(options.table or options.vector)
				and (options.value or (job.language ~= "python" and job.language ~= "python3"))
			)
			or (
				options.value
				and type(result.value) == "table"
				and not options.verbatim
				and not options.scalar
				and not options.list
			)
		)
	then
		local value = result.value
		if not options.value then
			value = {}
			for _, line in ipairs(vim.split(output, "\n", { plain = true })) do
				value[#value + 1] = vim.split(line, line:find("\t", 1, true) and "\t" or "%s+", { trimempty = true })
			end
		end
		content = table_lines(value, options.value and job.table_header or nil)
	elseif options.list and not error_output then
		content = {}
		local value = result.value
		if not options.value then
			value = output
		end
		if type(value) == "table" then
			for _, item in ipairs(value) do
				content[#content + 1] = "- " .. scalar(item)
			end
		else
			content = { ": - " .. scalar(value) }
		end
	else
		content = vim.split(output, "\n", { plain = true })
		if
			not options.raw
			and not options.code
			and not options.drawer
			and not options.html
			and not options.latex
			and not options.org
			and not job.args.wrap
		then
			for i, line in ipairs(content) do
				content[i] = ": " .. line
			end
		end
	end
	if not wrap then
		if options.code then
			wrap = "src " .. job.language
		elseif options.org then
			wrap = "src org"
		elseif options.html then
			wrap = "export html"
		elseif options.latex then
			wrap = "export latex"
		end
	end
	if wrap then
		table.insert(content, 1, "#+begin_" .. wrap)
		content[#content + 1] = "#+end_" .. wrap:match("^%S+")
	elseif options.drawer then
		table.insert(content, 1, ":results:")
		content[#content + 1] = ":end:"
	end
	for i, line in ipairs(content) do
		content[i] = job.indent .. line
	end
	return content
end

return M
