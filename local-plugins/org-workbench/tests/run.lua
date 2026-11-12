local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.opt.hidden = true
vim.cmd("filetype plugin indent on")
local tmp = vim.fn.tempname() .. " org | workbench"
local total = 0
local function eq(expected, actual)
	total = total + 1
	assert(vim.deep_equal(expected, actual), "expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end
local function lines(value)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, value)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
end
local function text()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end
local ok, err = xpcall(function()
	local parser = require("org_workbench.parser")
	local plugin = require("org_workbench")
	local editor = require("org_workbench.editor")
	local views = require("org_workbench.views")
	local doc = parser.parse({
		"#+TODO: OPEN(o) WAIT(w) | CLOSED(c)",
		"* OPEN [#A] Projeto :work:code:",
		"SCHEDULED: <2026-10-20 Tue> DEADLINE: <2026-10-22 Thu>",
		"#+begin_src lua",
		"* literal",
		"#+TODO: WRONG | WRONGER",
		"#+end_src",
		"** WAIT Filho",
		"* CLOSED Outra",
	})
	eq(3, #doc.headings)
	eq("Projeto", doc.headings[1].title)
	eq("A", doc.headings[1].priority)
	eq(":work:code:", doc.headings[1].tags)
	eq("2026-10-20", doc.headings[1].scheduled)
	eq("2026-10-22", doc.headings[1].deadline)
	eq(8, doc.headings[1].end_line)
	eq(doc.headings[1], doc.headings[2].parent)
	eq(true, doc.done.CLOSED)
	eq(true, doc.blocks[1].closed)
	eq(nil, parser.date("2026-02-30"))
	eq(nil, parser.date("2025-02-29"))
	eq("number", type(parser.date("2024-02-29")))
	eq(false, parser.parse({ "#+begin_src lua", "* literal" }).blocks[1].closed)
	eq(0, #parser.parse({ "#+begin_example", "* literal", "#+end_example" }).headings)

	plugin.setup({ directory = tmp })
	eq(0, vim.fn.isdirectory(tmp))
	eq(nil, package.loaded.orgmode)
	vim.cmd("OrgWorkbench inbox")
	local inbox = vim.api.nvim_get_current_buf()
	eq(tmp .. "/inbox.org", vim.api.nvim_buf_get_name(0))
	eq("org", vim.bo.filetype)
	eq("Org todo", vim.fn.maparg("<C-c><C-t>", "n", false, true).desc)
	lines({
		"* TODO [#A] Projeto :work:",
		"Texto preservado.",
		"** TODO Filho",
		"#+begin_src lua",
		"* literal",
		"#+end_src",
		"* DONE Outra",
	})
	vim.cmd("OrgWorkbench todo")
	eq("* NEXT [#A] Projeto :work:", text()[1])
	eq("Texto preservado.", text()[2])
	vim.cmd("OrgWorkbench demote")
	eq("** NEXT [#A] Projeto :work:", text()[1])
	eq("*** TODO Filho", text()[3])
	eq("* literal", text()[5])
	vim.cmd("OrgWorkbench promote")
	eq("* NEXT [#A] Projeto :work:", text()[1])
	eq("** TODO Filho", text()[3])
	vim.cmd("OrgWorkbench schedule 2026-10-20")
	vim.cmd("OrgWorkbench deadline 2026-10-22")
	eq("SCHEDULED: <2026-10-20> DEADLINE: <2026-10-22>", text()[2])
	vim.cmd("OrgWorkbench schedule 2026-10-21")
	eq("SCHEDULED: <2026-10-21> DEADLINE: <2026-10-22>", text()[2])
	eq(">1", plugin.foldexpr(1))
	eq(1, plugin.foldexpr(2))
	eq(">2", plugin.foldexpr(4))
	vim.api.nvim_win_set_cursor(0, { 6, 0 })
	eq(false, pcall(editor.todo))
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	editor.clock_in()
	eq(true, text()[3]:match("^CLOCK:") ~= nil)
	editor.plan("SCHEDULED", "2026-10-23")
	eq("2026-10-23", editor.document().headings[1].scheduled)
	vim.api.nvim_buf_set_lines(0, 0, 0, false, { "#+title: Relógio" })
	editor.clock_out()
	eq(true, text()[4]:match(" => 0:00$") ~= nil)
	eq(nil, editor.clock)

	lines({ "* TODO Tarefa", "- [ ] item", "1. [-] parcial" })
	vim.api.nvim_win_set_cursor(0, { 2, 0 })
	editor.checkbox()
	eq("- [X] item", text()[2])
	editor.checkbox()
	eq("- [ ] item", text()[2])
	vim.api.nvim_win_set_cursor(0, { 3, 0 })
	editor.checkbox()
	eq("1. [ ] parcial", text()[3])

	lines({ "| Nome | Número |", "|---+---|", "| café | 1 |", "| x | 1234 |" })
	editor.table_align()
	eq({ "| Nome | Número |", "|------+--------|", "| café | 1      |", "| x    | 1234   |" }, text())

	lines({ "* Código", "#+begin_src lua :tangle hello.lua", "print('<hello>')", "#+end_src", "* TODO Filha" })
	vim.cmd("silent write")
	vim.api.nvim_win_set_cursor(0, { 3, 0 })
	editor.edit_source()
	eq("lua", vim.bo.filetype)
	eq({ "print('<hello>')" }, text())
	lines({ "print('changed')", "print('two')" })
	vim.cmd("write")
	eq(false, vim.bo.modified)
	vim.cmd("close")
	eq(inbox, vim.api.nvim_get_current_buf())
	eq("print('changed')", text()[3])
	eq("#+end_src", text()[5])
	views.tangle()
	eq({ "print('changed')", "print('two')" }, vim.fn.readfile(tmp .. "/hello.lua"))
	local source_with_results = text()
	lines({
		"#+PROPERTY: header-args:lua :tangle composed.lua :noweb yes",
		"#+name: fragment",
		"#+begin_src lua :tangle no",
		"print('herdado')",
		"#+end_src",
		"#+begin_src lua",
		"<<fragment>>",
		"#+end_src",
	})
	views.tangle()
	eq({ "print('herdado')" }, vim.fn.readfile(tmp .. "/composed.lua"))
	lines(source_with_results)
	views.export_html()
	eq(true, table.concat(vim.fn.readfile(tmp .. "/inbox.org.html"), "\n"):find("<h1>Código</h1>", 1, true) ~= nil)

	-- Captures append to loaded buffers, preserving their unsaved changes.
	lines({ "* TODO Antes" })
	views.capture("t")
	local capture = vim.api.nvim_get_current_buf()
	lines({ "* TODO Capturada" })
	vim.cmd("write")
	eq({ "* TODO Antes", "* TODO Capturada" }, vim.fn.readfile(tmp .. "/inbox.org"))
	vim.cmd("write")
	eq(2, #vim.fn.readfile(tmp .. "/inbox.org"))
	eq(false, vim.bo[capture].modified)
	vim.cmd("close")
	eq(2, #views.entries(true))
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "* DONE Finalizada", "* TODO Nova", "DEADLINE: <2000-01-01>" })
	eq(1, #views.entries(true))
	eq("2000-01-01  TODO  Nova", views.entries(false)[1].text)
	views.agenda(false)
	eq(1, #vim.fn.getqflist())
	vim.cmd("cclose")

	-- Moving a subtree preserves destination edits and leaves both buffers dirty.
	vim.api.nvim_set_current_buf(inbox)
	lines({ "* TODO Pai", "** TODO Filho", "texto", "* TODO Outra" })
	editor.refile(tmp .. "/destino.org")
	eq({ "* TODO Outra" }, text())
	local target = vim.fn.bufnr(tmp .. "/destino.org")
	eq({ "* TODO Pai", "** TODO Filho", "texto" }, vim.api.nvim_buf_get_lines(target, 0, -1, false))
	eq(true, vim.bo[target].modified)
	eq(true, vim.bo[inbox].modified)
	editor.refile(nil, true)
	eq({ "* TODO Outra" }, vim.api.nvim_buf_get_lines(vim.fn.bufnr(tmp .. "/inbox.org_archive"), 0, -1, false))

	lines({ "* Destino", "[[*Destino][ir]]" })
	vim.api.nvim_win_set_cursor(0, { 2, 3 })
	plugin.open_link()
	eq(1, vim.api.nvim_win_get_cursor(0)[1])
	eq(nil, package.loaded.orgmode)
	print("Org Workbench: " .. total .. " verificações passaram, sem nvim-orgmode")
end, debug.traceback)

vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
if not ok then
	io.stderr:write(err .. "\n")
	vim.cmd("cquit 1")
end
vim.cmd("qa!")
