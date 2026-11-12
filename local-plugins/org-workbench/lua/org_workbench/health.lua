local M = {}

function M.check()
	vim.health.start("Org Workbench — implementação independente")
	if vim.fn.has("nvim-0.11") == 1 then
		vim.health.ok("Neovim >= 0.11")
	else
		vim.health.error("Requer Neovim >= 0.11")
	end
	vim.health.ok("Sem dependência de orgmode, Tree-sitter, Emacs ou Pandoc")
	local config = require("org_workbench").config
	if config then
		vim.health.ok("Diretório: " .. config.directory)
	else
		vim.health.warn("Execute require('org_workbench').setup()")
	end
end

return M
