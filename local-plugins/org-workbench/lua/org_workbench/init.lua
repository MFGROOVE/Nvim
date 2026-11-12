local parser = require("org_workbench.parser")
local editor = require("org_workbench.editor")
local views = require("org_workbench.views")
local babel = require("org_workbench.babel")
local M = {}
local folds = {}

function M.foldexpr(row)
	local buf, tick = vim.api.nvim_get_current_buf(), vim.b.changedtick
	if not folds[buf] or folds[buf].tick ~= tick then
		local doc, levels, level = editor.document(buf), {}, 0
		local headings = {}
		for _, h in ipairs(doc.headings) do
			headings[h.line] = h
		end
		for i = 1, #doc.lines do
			if headings[i] then
				level = headings[i].level
				levels[i] = ">" .. level
			else
				levels[i] = level
			end
		end
		folds[buf] = { tick = tick, levels = levels }
	end
	return folds[buf].levels[row] or 0
end

function M.open_link()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local target
	for first, value, after in line:gmatch("()%[%[([^%]]+)%]()") do
		local last = line:find("]]", after - 1, true)
		if last and col >= first and col <= last + 1 then
			target = value
			break
		end
	end
	assert(target, "Posicione o cursor em um link [[destino]]")
	if target:match("^https?://") or target:match("^mailto:") then
		local _, err = vim.ui.open(target)
		assert(not err, err)
	elseif target:sub(1, 1) == "*" then
		local title = target:gsub("^%*+", "")
		for _, h in ipairs(editor.document().headings) do
			if h.title == title then
				vim.api.nvim_win_set_cursor(0, { h.line, 0 })
				return
			end
		end
		error("Título não encontrado: " .. title)
	else
		assert(target:sub(1, 5) == "file:", "Tipo de link ainda não suportado")
		local path, search = target:sub(6):match("^(.-)::(.*)$")
		path = path or target:sub(6)
		path = vim.fn.expand(path)
		if not vim.startswith(path, "/") then
			path = vim.fs.joinpath(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h"), path)
		end
		vim.api.nvim_cmd({ cmd = "edit", args = { path } }, {})
		if search and tonumber(search) then
			vim.api.nvim_win_set_cursor(
				0,
				{ math.max(1, math.min(tonumber(search), vim.api.nvim_buf_line_count(0))), 0 }
			)
		elseif search then
			vim.fn.search("\\V" .. search:gsub("\\", "\\\\"), "w")
		end
	end
end

local function date_prompt(kind, value)
	if value and value ~= "" then
		return editor.plan(kind, value)
	end
	local buf, position = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)
	vim.ui.input({ prompt = kind .. " (AAAA-MM-DD): ", default = os.date("%Y-%m-%d") }, function(answer)
		if not answer then
			return
		end
		if vim.api.nvim_get_current_buf() ~= buf or not vim.deep_equal(position, vim.api.nvim_win_get_cursor(0)) then
			vim.notify("O cursor mudou; execute o comando de data novamente.", vim.log.levels.WARN)
			return
		end
		local ok, err = pcall(editor.plan, kind, answer)
		if not ok then
			vim.notify(tostring(err), vim.log.levels.ERROR)
		end
	end)
end

local actions = {
	agenda = {
		function()
			views.agenda(false)
		end,
	},
	todos = {
		function()
			views.agenda(true)
		end,
	},
	capture = {
		function(arg)
			views.capture(arg)
		end,
	},
	inbox = {
		function()
			views.open(M.config.directory .. "/inbox.org")
		end,
	},
	journal = {
		function()
			views.open(M.config.directory .. "/journal.org")
		end,
	},
	todo = { editor.todo, true },
	promote = {
		function()
			editor.shift(-1)
		end,
		true,
	},
	demote = {
		function()
			editor.shift(1)
		end,
		true,
	},
	heading = { editor.heading, true },
	checkbox = { editor.checkbox, true },
	schedule = {
		function(arg)
			date_prompt("SCHEDULED", arg)
		end,
		true,
	},
	deadline = {
		function(arg)
			date_prompt("DEADLINE", arg)
		end,
		true,
	},
	refile = {
		function(arg)
			editor.refile(arg)
		end,
		true,
	},
	archive = {
		function()
			editor.refile(nil, true)
		end,
		true,
	},
	["clock-in"] = { editor.clock_in, true },
	["clock-out"] = { editor.clock_out },
	["edit-source"] = { editor.edit_source, true },
	["insert-block"] = { babel.insert, true },
	execute = { babel.execute, true },
	["execute-all"] = { babel.execute_all, true },
	["session-reset"] = { babel.reset_session },
	["cancel-execution"] = { babel.cancel, true },
	["table-align"] = { editor.table_align, true },
	export = {
		function(arg)
			views.export_html(arg ~= "" and arg or nil)
		end,
		true,
	},
	tangle = { views.tangle, true },
	link = { M.open_link, true },
}

function M.run(name, arg)
	local ok, err = pcall(function()
		local action = assert(actions[name], "Ação desconhecida: " .. tostring(name))
		assert(not action[2] or vim.bo.filetype == "org", "Abra um arquivo .org para usar esta ação")
		action[1](arg)
	end)
	if not ok then
		vim.notify(tostring(err), vim.log.levels.ERROR)
	end
	return ok, err
end

local function attach(buf)
	vim.bo[buf].commentstring = "# %s"
	vim.bo[buf].modeline = false
	vim.wo.foldmethod = "expr"
	vim.wo.foldexpr = "v:lua.require('org_workbench').foldexpr(v:lnum)"
	vim.wo.foldlevel = 99
	local mappings = {
		["<localleader>ot"] = "todo",
		["<localleader>os"] = "schedule",
		["<localleader>od"] = "deadline",
		["<localleader>ox"] = "checkbox",
		["<localleader>o$"] = "archive",
		["<localleader>oe"] = "export",
		["<localleader>obt"] = "tangle",
		["<localleader>obi"] = "insert-block",
		["<localleader>obx"] = "execute",
		["<localleader>oba"] = "execute-all",
		["<localleader>obr"] = "session-reset",
		["<localleader>obk"] = "cancel-execution",
		["<localleader>oxi"] = "clock-in",
		["<localleader>oxo"] = "clock-out",
		["<localleader>o'"] = "edit-source",
		["<localleader>o="] = "table-align",
		["<localleader>oo"] = "link",
		["<M-Left>"] = "promote",
		["<M-Right>"] = "demote",
		["<M-CR>"] = "heading",
	}
	if M.config.emacs_keys then
		mappings["<C-c><C-c>"] = "execute"
		mappings["<C-c><C-t>"], mappings["<C-c><C-s>"], mappings["<C-c><C-d>"] = "todo", "schedule", "deadline"
		mappings["<C-c><C-e>"], mappings["<C-c><C-o>"], mappings["<C-c>'"] = "export", "link", "edit-source"
		mappings["<C-Space>"] = "checkbox"
	end
	for lhs, action in pairs(mappings) do
		vim.keymap.set("n", lhs, function()
			M.run(action)
		end, { buffer = buf, silent = true, desc = "Org " .. action })
	end
	vim.keymap.set("n", "<Tab>", "za", { buffer = buf, desc = "Org alternar dobra" })
	vim.keymap.set("n", "<S-Tab>", function()
		if vim.wo.foldlevel == 0 then
			vim.cmd("normal! zR")
		else
			vim.cmd("normal! zM")
		end
	end, { buffer = buf, desc = "Org alternar todas as dobras" })
	vim.api.nvim_buf_call(buf, function()
		vim.cmd([[
syntax clear
syntax match OrgHeading /^\*\+\s.*/
syntax match OrgTodo /\<\(TODO\|NEXT\|WAITING\)\>/
syntax match OrgDone /\<\(DONE\|CANCELLED\)\>/
syntax match OrgLink /\[\[.\{-}\]\]/
syntax match OrgDate /[<[]\d\{4}-\d\{2}-\d\{2}[^]>]*[]>]/
syntax match OrgDirective /^\s*#+.*/
syntax region OrgBlock start=/\c^\s*#+begin_src\>/ end=/\c^\s*#+end_src\>/ keepend
highlight default link OrgHeading Title
highlight default link OrgTodo Todo
highlight default link OrgDone Comment
highlight default link OrgLink Underlined
highlight default link OrgDate Constant
highlight default link OrgDirective PreProc
highlight default link OrgBlock String
]])
	end)
end

function M.setup(opts)
	opts = opts or {}
	local directory = vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(opts.directory or "~/org"), ":p"))
	M.config = vim.tbl_deep_extend("force", {
		directory = directory,
		agenda_files = { directory .. "/**/*.org" },
		agenda_days = 7,
		todo_keywords = "TODO NEXT WAITING | DONE CANCELLED",
		emacs_keys = true,
		babel = {
			default_header_args = ":results value replace",
			timeout_ms = 10000,
			max_output_bytes = 1000000,
			runners = {
				python = { "python3", "{file}" },
				python3 = { "python3", "{file}" },
				lua = { "lua", "{file}" },
				javascript = { "node", "{file}" },
				js = { "node", "{file}" },
				sh = { "sh", "{file}" },
				shell = { "sh", "{file}" },
				bash = { "bash", "{file}" },
				ruby = { "ruby", "{file}" },
				perl = { "perl", "{file}" },
				r = { "Rscript", "{file}" },
			},
		},
		capture_templates = {
			t = { description = "Tarefa", template = "* TODO %?\n%U", target = directory .. "/inbox.org" },
			n = { description = "Nota", template = "* %?\n%U", target = directory .. "/notes.org" },
			j = { description = "Diário", template = "* %<%Y-%m-%d %H:%M> %?", target = directory .. "/journal.org" },
		},
	}, opts)
	M.config.directory = directory
	assert(type(M.config.agenda_days) == "number" and M.config.agenda_days >= 1, "agenda_days deve ser positivo")
	assert(
		type(M.config.babel.timeout_ms) == "number" and M.config.babel.timeout_ms > 0,
		"babel.timeout_ms deve ser positivo"
	)
	assert(
		type(M.config.babel.max_output_bytes) == "number" and M.config.babel.max_output_bytes > 0,
		"babel.max_output_bytes deve ser positivo"
	)
	editor.config, views.config = M.config, M.config
	babel.config = M.config.babel
	vim.filetype.add({ extension = { org = "org", org_archive = "org" } })
	vim.api.nvim_create_user_command("OrgWorkbench", function(args)
		if #args.fargs == 0 then
			local names = vim.tbl_keys(actions)
			table.sort(names)
			vim.ui.select(names, { prompt = "Org Workbench" }, function(name)
				if name then
					M.run(name)
				end
			end)
		else
			M.run(args.fargs[1], table.concat(args.fargs, " ", 2))
		end
	end, {
		nargs = "*",
		force = true,
		desc = "Org Workbench independente",
		complete = function(prefix)
			local names = vim.tbl_filter(function(name)
				return vim.startswith(name, prefix)
			end, vim.tbl_keys(actions))
			table.sort(names)
			return names
		end,
	})
	local group = vim.api.nvim_create_augroup("org_workbench", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "org",
		callback = function(event)
			attach(event.buf)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(event)
			folds[event.buf] = nil
		end,
	})
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "org" then
			vim.api.nvim_buf_call(buf, function()
				attach(buf)
			end)
		end
	end
end

return M
