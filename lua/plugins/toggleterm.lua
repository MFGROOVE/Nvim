return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		cmd = "ToggleTerm",
		keys = { { "<leader>ut", desc = "Toggle Terminal" } },
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
			-- <Esc> só nos terminais do toggleterm, para não quebrar fzf/lazygit em outros terminais
			vim.api.nvim_create_autocmd("TermOpen", {
				pattern = "term://*toggleterm#*",
				callback = function(args)
					vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = args.buf, silent = true })
				end,
			})
		end,
	},
}
