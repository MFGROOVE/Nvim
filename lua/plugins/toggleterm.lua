return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			require("toggleterm").setup({
				direction = "horizontal",
				border = "curved",
				size = 30,
			})
			vim.keymap.set(
				"n",
				"<leader>ut",
				"<cmd>ToggleTerm<CR>",
				{ noremap = true, silent = true, desc = "Toggle Terminal" }
			)
			vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })
		end,
	},
}
