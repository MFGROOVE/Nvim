return {
	"folke/todo-comments.nvim",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{ "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Find TODOs" },
		{ "<leader>qt", "<cmd>TodoTrouble<CR>", desc = "Trouble TODOs" },
	},
	opts = {},
}
