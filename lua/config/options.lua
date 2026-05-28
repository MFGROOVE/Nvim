vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.wrap = false
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.autoindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 999
vim.opt.virtualedit = "block"
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.termguicolors = true
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function()
		local bufname = vim.api.nvim_buf_get_name(0)
		if bufname == "" then
			return
		end
		local dir = vim.fn.fnamemodify(bufname, ":h")
		if vim.fn.isdirectory(dir) == 1 and dir:match("^/home/") then
			vim.cmd.lcd(dir)
		end
	end,
})
vim.opt.updatetime = 300
vim.opt.laststatus = 3
vim.opt.fileencoding = "utf-8"
vim.opt.fileformat = "unix"
vim.opt.fixendofline = true
vim.opt.swapfile = false

vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

function _G.safe_foldexpr()
	local ok, result = pcall(vim.treesitter.foldexpr)
	if ok then
		return result
	end
	return "0"
end

vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		local ok = pcall(vim.treesitter.get_parser, 0)
		if ok then
			vim.wo.foldmethod = "expr"
			vim.wo.foldexpr = "v:lua.safe_foldexpr()"
		end
	end,
})

vim.opt.cinoptions = "g0,:0"

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp" },
	callback = function()
		vim.bo.cindent = true
	end,
})

vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
		focusable = false,
	},
})
