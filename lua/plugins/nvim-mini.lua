return {
	"echasnovski/mini.nvim",
	version = false,
	event = "VeryLazy",
	config = function()
		require("mini.move").setup({
			mappings = {
				left = "<A-h>",
				right = "<A-l>",
				down = "<A-j>",
				up = "<A-k>",
				line_left = "<A-h>",
				line_right = "<A-l>",
				line_down = "<A-j>",
				line_up = "<A-k>",
			},
		})

		require("mini.surround").setup({
			mappings = {
				add = "ys",
				delete = "ds",
				replace = "cs",
				find = "",
				find_left = "",
				highlight = "",
				update_n_lines = "",
			},
			search_method = "cover",
		})

		vim.keymap.set("x", "s", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
		vim.keymap.set("x", "ds", [[:<C-u>lua MiniSurround.delete()<CR>]], { silent = true })
	end,
}
