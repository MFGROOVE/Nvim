local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.opt.hidden = true
vim.cmd("filetype plugin indent on")
local tmp = vim.fn.tempname() .. " babel | tests"
vim.fn.mkdir(tmp .. "/sub dir", "p")
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
local function wait(job)
	assert(
		vim.wait(5000, function()
			return job.done
		end, 10),
		"execution did not finish"
	)
	eq(nil, job.error)
	return job
end
local ok, err = xpcall(function()
	require("org_workbench").setup({ directory = tmp, babel = { default_header_args = ":results output replace" } })
	local babel = require("org_workbench.babel")
	vim.api.nvim_cmd({ cmd = "edit", args = { tmp .. "/examples.org" } }, {})
	eq("Org execute", vim.fn.maparg("<C-c><C-c>", "n", false, true).desc)
	eq("Org execute", vim.fn.maparg("\\obx", "n", false, true).desc)
	lines({ "#+begin_src python :results output", "print(6 * 7)", "print('olá')", "#+end_src", "Texto preservado." })
	wait(babel.execute())
	eq({
		"#+begin_src python :results output",
		"print(6 * 7)",
		"print('olá')",
		"#+end_src",
		"#+RESULTS:",
		": 42",
		": olá",
		"Texto preservado.",
	}, text())
	wait(babel.execute())
	eq(8, #text())
	eq(nil, babel.running[vim.api.nvim_get_current_buf()])
	lines({ "  #+begin_src python", "    for x in range(2):", "        print(x)", "  #+end_src" })
	wait(babel.execute())
	eq("  : 0", text()[6])
	eq("  : 1", text()[7])

	for _, item in ipairs({
		{ "lua", "print(21 * 2)" },
		{ "javascript", "console.log(21 * 2)" },
		{ "sh", "printf '42\\n'" },
		{ "bash", "printf '%s\\n' 42" },
	}) do
		lines({ "#+begin_src " .. item[1], item[2], "#+end_src" })
		wait(babel.execute())
		eq(": 42", text()[5])
	end

	lines({ '#+begin_src python :dir "sub dir"', "import os; print(os.path.basename(os.getcwd()))", "#+end_src" })
	wait(babel.execute())
	eq(": sub dir", text()[5])
	lines({ "#+begin_src python", "raise ValueError('falhou')", "#+end_src" })
	local failed = wait(babel.execute())
	eq(1, failed.result.code)
	eq(true, table.concat(text(), "\n"):find("ValueError: falhou", 1, true) ~= nil)
	eq(": [Processo terminou com código 1]", text()[#text()])

	lines({ "#+begin_src python", "pass", "#+end_src", "", "#+RESULTS:", ": antigo", "* Próximo título" })
	wait(babel.execute())
	eq({ "#+begin_src python", "pass", "#+end_src", "", "#+RESULTS:", ": ", "* Próximo título" }, text())
	lines({
		"#+begin_src python",
		"print('novo')",
		"#+end_src",
		"#+RESULTS:",
		": antigo",
		"#+begin_src lua",
		"print(1)",
		"#+end_src",
	})
	wait(babel.execute())
	eq("#+begin_src lua", text()[6])

	-- Work can move while running, but edits to its source must not be overwritten.
	lines({ "#+begin_src python", "import time; time.sleep(0.1); print('ok')", "#+end_src" })
	local moved = babel.execute()
	eq(false, pcall(babel.execute))
	vim.api.nvim_buf_set_lines(0, 0, 0, false, { "* Antes" })
	wait(moved)
	eq(": ok", text()[6])
	lines({ "#+begin_src python", "import time; time.sleep(0.1); print('ok')", "#+end_src" })
	local changed = babel.execute()
	vim.api.nvim_buf_set_lines(0, 1, 2, false, { "print('editado')" })
	assert(vim.wait(5000, function()
		return changed.done
	end, 10))
	eq(true, changed.error:find("bloco mudou", 1, true) ~= nil)
	eq(3, #text())

	lines({ "#+begin_src python", "import time; time.sleep(5)", "#+end_src" })
	babel.config.timeout_ms = 100
	local timed = wait(babel.execute())
	eq(124, timed.result.code)
	eq(true, table.concat(text(), "\n"):find("Tempo limite excedido", 1, true) ~= nil)
	babel.config.timeout_ms = 10000
	lines({ "#+begin_src python", "import time; time.sleep(5)", "#+end_src" })
	local cancelled = babel.execute()
	babel.cancel()
	wait(cancelled)
	eq(true, table.concat(text(), "\n"):find("Execução cancelada", 1, true) ~= nil)

	for _, args in ipairs({ ":eval never", ":stdin teste", ":results desconhecido", ':dir "aspas abertas' }) do
		lines({ "#+begin_src python " .. args, "print(1)", "#+end_src" })
		eq(false, pcall(babel.execute))
		eq(3, #text())
	end
	lines({ "#+begin_src inexistente", "print(1)", "#+end_src" })
	eq(false, pcall(babel.execute))
	lines({ "#+begin_src python", "print(1)" })
	eq(false, pcall(babel.execute))
	lines({ "* Exemplos" })
	babel.insert("python")
	eq({ "* Exemplos", "#+begin_src python :results output", "", "#+end_src" }, text())
	eq(3, vim.api.nvim_win_get_cursor(0)[1])
	eq(nil, package.loaded.orgmode)
	dofile(root .. "/tests/advanced.lua")(eq, wait, lines, text, tmp, root)
	print("Org Babel: " .. total .. " verificações passaram")
end, debug.traceback)
vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
if not ok then
	io.stderr:write(err .. "\n")
	vim.cmd("cquit 1")
end
vim.cmd("qa!")
