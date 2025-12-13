return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },

		opts = {
			defaults = {
				path_display = { "truncate" },
				mappings = {
					i = { ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" },
				},
			},
			pickers = { find_files = { hidden = true } },
		},

		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols List" },
			{ "fr", "<cmd>Telescope lsp_references<cr>", desc = "Goto References" },
		},
	},
}
