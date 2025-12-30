local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")

vim.opt.fileencoding = "utf-8"
vim.opt.fileformat = "unix"
vim.opt.fixendofline = true

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		local save_cursor = vim.fn.getpos(".")
		vim.cmd([[%s/\s\+$//e]])
		vim.fn.setpos(".", save_cursor)
	end,
})

local function set_indent(size, is_tab, text_width)
	vim.opt_local.expandtab = not is_tab
	vim.opt_local.shiftwidth = size
	vim.opt_local.tabstop = size
	vim.opt_local.softtabstop = size
	if text_width then
		vim.opt_local.textwidth = text_width
		vim.opt_local.colorcolumn = tostring(text_width)
	end
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp", "java" },
	callback = function(ev)
		vim.opt_local.cindent = false
		vim.opt_local.smartindent = false
		vim.opt_local.autoindent = true

		if ev.match == "java" then
			set_indent(4, false, 120)
		else
			set_indent(2, false, 100)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python", "rust" },
	callback = function()
		set_indent(4, false)
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "make",
	callback = function()
		set_indent(8, true)
	end,
})

vim.keymap.set("n", "<leader>uh", function()
    if vim.lsp.inlay_hint then
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        print("Inlay Hints: " .. (vim.lsp.inlay_hint.is_enabled() and "ON" or "OFF"))
    else
        print("Sua versão do Neovim não suporta Inlay Hints nativos")
    end
end, { desc = "Toggle Inlay Hints" })

require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	install = { colorscheme = { "tokyonight-night" } },
	checker = { enabled = true },
})
