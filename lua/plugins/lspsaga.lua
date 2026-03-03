return {
	"nvimdev/lspsaga.nvim",
	event = "LspAttach",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("lspsaga").setup({
			ui = {
				border = "rounded",
			},
			lightbulb = {
				enable = false,
			},
			symbol_in_winbar = {
				enable = true,
			},
		})

		local opts = { noremap = true, silent = true }

		vim.keymap.set("n", "<leader>ld", "<cmd>Lspsaga goto_definition<CR>", opts)
		vim.keymap.set("n", "<leader>lr", "<cmd>Lspsaga finder<CR>", opts)
		vim.keymap.set("n", "<leader>ln", "<cmd>Lspsaga rename<CR>", opts)
		vim.keymap.set({ "n", "v" }, "<leader>la", "<cmd>Lspsaga code_action<CR>", opts)
		vim.keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", opts)
		vim.keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", opts)
		vim.keymap.set("n", "<leader>li", "<cmd>Lspsaga hover_doc<CR>", opts)
	end,
}
