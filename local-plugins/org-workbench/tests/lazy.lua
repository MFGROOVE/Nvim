local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config = vim.fn.fnamemodify(root, ":h:h")
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
vim.opt.runtimepath:prepend(vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
vim.go.loadplugins = true
vim.g.mapleader, vim.g.maplocalleader = "\\", "\\"
local spec = dofile(config .. "/lua/plugins/org.lua")
spec[1].config = function()
	require("org_workbench").setup({ directory = tmp })
end
local ok, err = xpcall(function()
	require("lazy").setup({
		spec = spec,
		lockfile = tmp .. "/lock.json",
		checker = { enabled = false },
		change_detection = { enabled = false },
		install = { missing = false },
		readme = { enabled = false },
	})
	assert(package.loaded.org_workbench == nil)
	vim.cmd("OrgWorkbench inbox")
	assert(vim.bo.filetype == "org")
	assert(vim.fn.maparg("<C-c><C-c>", "n", false, true).desc == "Org execute")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "#+begin_src python :results output", "print(6 * 7)", "#+end_src" })
	vim.cmd("OrgWorkbench execute")
	assert(vim.wait(5000, function()
		return require("org_workbench.babel").running[vim.api.nvim_get_current_buf()] == nil
	end, 10))
	assert(vim.api.nvim_buf_get_lines(0, 4, 5, false)[1] == ": 42")
	assert(package.loaded.orgmode == nil)
	print("lazy.nvim: carregamento, atalhos e execução de Python OK")
end, debug.traceback)
vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
if not ok then
	io.stderr:write(err .. "\n")
	vim.cmd("cquit 1")
end
vim.cmd("qa!")
