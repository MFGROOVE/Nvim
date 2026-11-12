local parser = require("org_workbench.parser")
local editor = require("org_workbench.editor")
local M = {}

function M.open(path)
	path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	vim.api.nvim_cmd({ cmd = "edit", args = { path } }, {})
end

function M.entries(todos)
	local paths, seen, entries = {}, {}, {}
	for _, pattern in ipairs(M.config.agenda_files) do
		vim.list_extend(paths, vim.fn.glob(vim.fn.expand(pattern), false, true))
	end
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if vim.api.nvim_buf_is_loaded(buf) and name:sub(-4) == ".org" then
			-- Include unsaved files only inside the configured agenda scope.
			for _, pattern in ipairs(M.config.agenda_files) do
				if vim.fn.match(name, vim.fn.glob2regpat(vim.fn.expand(pattern))) >= 0 then
					paths[#paths + 1] = name
					break
				end
			end
		end
	end
	local today = os.date("%Y-%m-%d")
	local future = os.date(
		"%Y-%m-%d",
		os.time({
			year = tonumber(today:sub(1, 4)),
			month = tonumber(today:sub(6, 7)),
			day = tonumber(today:sub(9, 10)) + M.config.agenda_days - 1,
			hour = 12,
		})
	)
	for _, path in ipairs(paths) do
		path = vim.fn.fnamemodify(path, ":p")
		if not seen[path] and vim.fn.isdirectory(path) == 0 then
			seen[path] = true
			local buf = vim.fn.bufnr(path)
			local lines
			if buf >= 0 and vim.api.nvim_buf_is_loaded(buf) then
				lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			elseif vim.fn.filereadable(path) == 1 then
				lines = vim.fn.readfile(path)
			end
			if lines then
				local doc = parser.parse(lines, M.config.todo_keywords)
				for _, h in ipairs(doc.headings) do
					local date = h.deadline or h.scheduled
					if h.scheduled and (not date or h.scheduled < date) then
						date = h.scheduled
					end
					if not doc.done[h.todo] and ((todos and h.todo) or (not todos and date and date <= future)) then
						entries[#entries + 1] = {
							filename = path,
							lnum = h.line,
							col = 1,
							text = (date or "Sem data") .. "  " .. (h.todo or "") .. "  " .. h.title,
							user_data = { date = date or "9999-12-31" },
						}
					end
				end
			end
		end
	end
	table.sort(entries, function(a, b)
		if a.user_data.date == b.user_data.date then
			return a.filename == b.filename and a.lnum < b.lnum or a.filename < b.filename
		end
		return a.user_data.date < b.user_data.date
	end)
	return entries
end

function M.agenda(todos)
	vim.fn.setqflist(
		{},
		" ",
		{ title = todos and "Org: tarefas pendentes" or "Org: agenda e atrasos", items = M.entries(todos) }
	)
	vim.cmd("copen")
end

function M.capture(key)
	if not key or key == "" then
		local keys = vim.tbl_keys(M.config.capture_templates)
		table.sort(keys)
		vim.ui.select(keys, {
			prompt = "Org capture",
			format_item = function(item)
				return item .. " — " .. M.config.capture_templates[item].description
			end,
		}, function(choice)
			if choice then
				M.capture(choice)
			end
		end)
		return
	end
	local template = assert(M.config.capture_templates[key], "Template desconhecido: " .. key)
	local values = {
		U = os.date("[%Y-%m-%d %a %H:%M]"),
		u = os.date("[%Y-%m-%d %a]"),
		T = os.date("<%Y-%m-%d %a %H:%M>"),
		t = os.date("<%Y-%m-%d %a>"),
	}
	local text = template.template:gsub("%%([UuTt])", values)
	text = text:gsub("%%<([^>]+)>", function(format)
		return os.date(format)
	end)
	local marker = text:find("%?", 1, true)
	text = text:gsub("%%%?", "")
	vim.cmd("botright new")
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(buf, "org-workbench://capture/" .. buf)
	vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = "acwrite", "wipe", false
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
	vim.bo[buf].filetype = "org"
	vim.bo[buf].modified = true
	if marker then
		local before = text:sub(1, marker - 1)
		local _, count = before:gsub("\n", "")
		vim.api.nvim_win_set_cursor(0, { count + 1, #(before:match("[^\n]*$") or "") })
	end
	local finished = false
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			if finished then
				return
			end
			local path = vim.fn.fnamemodify(vim.fn.expand(template.target), ":p")
			vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
			local target = vim.fn.bufadd(path)
			vim.fn.bufload(target)
			assert(vim.bo[target].modifiable and not vim.bo[target].readonly, "Destino não pode ser editado")
			local original = vim.api.nvim_buf_get_lines(target, 0, -1, false)
			local was_modified = vim.bo[target].modified
			local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			local empty = #original == 1 and original[1] == ""
			vim.api.nvim_buf_set_lines(target, empty and 0 or -1, -1, false, content)
			local ok, err = pcall(vim.api.nvim_buf_call, target, function()
				vim.cmd("silent write")
			end)
			if not ok then
				vim.api.nvim_buf_set_lines(target, 0, -1, false, original)
				vim.bo[target].modified = was_modified
				error(err)
			end
			finished = true
			vim.bo[buf].modified, vim.bo[buf].modifiable = false, false
			vim.notify("Captura salva em " .. path .. ". Use :q para fechar.")
		end,
	})
	vim.keymap.set("n", "<C-c><C-c>", function()
		vim.cmd("write")
	end, { buffer = buf, desc = "Org finalizar captura" })
	vim.keymap.set("n", "<C-c><C-k>", function()
		vim.cmd("close!")
	end, { buffer = buf, desc = "Org cancelar captura" })
end

local function escape(text)
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

function M.export_html(path)
	local source = vim.api.nvim_buf_get_name(0)
	assert(source ~= "", "Salve o arquivo Org antes de exportar")
	path = path or (source .. ".html")
	assert(vim.fn.fnamemodify(path, ":p") ~= source, "A saída não pode sobrescrever o arquivo Org")
	local doc = editor.document()
	local headings = {}
	for _, h in ipairs(doc.headings) do
		headings[h.line] = h
	end
	local output = {
		"<!doctype html>",
		'<html lang="pt-BR"><meta charset="utf-8"><title>'
			.. escape(vim.fn.fnamemodify(source, ":t"))
			.. "</title><body>",
	}
	for row, line in ipairs(doc.lines) do
		local h = headings[row]
		if h then
			local level = math.min(h.level, 6)
			output[#output + 1] =
				string.format("<h%d>%s</h%d>", level, escape((h.todo and h.todo .. " " or "") .. h.title), level)
		else
			output[#output + 1] = '<pre style="white-space:pre-wrap;margin:0">' .. escape(line) .. "</pre>"
		end
	end
	output[#output + 1] = "</body></html>"
	vim.fn.writefile(output, path)
	vim.notify("HTML exportado: " .. path)
	return path
end

function M.tangle()
	local source = vim.api.nvim_buf_get_name(0)
	assert(source ~= "", "Salve o arquivo Org antes de extrair código")
	local doc, targets = editor.document(), {}
	local context = require("org_workbench.context")
	local headers = require("org_workbench.headers")
	local extensions = {
		python = "py",
		javascript = "js",
		typescript = "ts",
		bash = "sh",
		shell = "sh",
		lua = "lua",
		rust = "rs",
		c = "c",
		cpp = "cpp",
	}
	for _, block in ipairs(doc.blocks) do
		if block.kind == "src" and block.closed then
			local args = context.arguments(doc, block, M.config.babel)
			local target = headers.get(args, "tangle")
			if target and target ~= "no" then
				if target == "yes" then
					target = vim.fn.fnamemodify(source, ":r")
						.. "."
						.. (extensions[block.language] or block.language or "txt")
				elseif not vim.startswith(target, "/") then
					target = vim.fs.joinpath(vim.fn.fnamemodify(source, ":h"), target)
				end
				target = vim.fs.normalize(target)
				assert(target ~= source, "Tangle não pode sobrescrever o arquivo Org")
				assert(
					not targets[target] or targets[target].language == block.language,
					"Linguagens diferentes no mesmo destino"
				)
				targets[target] = targets[target] or { language = block.language, lines = {} }
				local noweb = headers.get(args, "noweb", "no")
				local body, dependencies
				if vim.tbl_contains({ "yes", "tangle", "no-export", "strip-export" }, noweb) then
					body, dependencies = context.expand(doc, block, M.config.babel)
				else
					body = context.body(doc, block)
				end
				assert(
					not dependencies or #dependencies == 0,
					"Tangle não avalia chamadas noweb; use referência de código <<nome>>"
				)
				vim.list_extend(targets[target].lines, vim.split(body, "\n", { plain = true }))
			end
		end
	end
	for path in pairs(targets) do
		local buf = vim.fn.bufnr(path)
		assert(buf < 0 or not vim.bo[buf].modified, "Destino tem alterações não salvas: " .. path)
	end
	for path, content in pairs(targets) do
		vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
		vim.fn.writefile(content.lines, path)
	end
	vim.notify("Tangle: " .. vim.tbl_count(targets) .. " arquivo(s) escrito(s)")
	return targets
end

return M
