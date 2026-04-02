return {
	"sindrets/diffview.nvim",
	cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
	keys = {
		{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff View" },
		{ "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File History" },
		{ "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Branch History" },
		{ "<leader>gx", "<cmd>DiffviewClose<CR>", desc = "Close Diff View" },
	},
	config = function()
		local actions = require("diffview.actions")

		require("diffview").setup({
			keymaps = {
				file_panel = {
					{ "n", "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "Close Diff View" } },
				},
				view = {
					{ "n", "<leader>gx", "<cmd>DiffviewClose<CR>", { desc = "Close Diff View" } },
					{ "n", "<leader>go", actions.conflict_choose("ours"), { desc = "Choose Ours" } },
					{ "n", "<leader>gt", actions.conflict_choose("theirs"), { desc = "Choose Theirs" } },
					{ "n", "<leader>gB", actions.conflict_choose("base"), { desc = "Choose Base" } },
					{ "n", "<leader>ga", actions.conflict_choose("all"), { desc = "Choose All" } },
					{ "n", "<leader>gO", actions.conflict_choose_all("ours"), { desc = "Choose Ours (all)" } },
					{ "n", "<leader>gT", actions.conflict_choose_all("theirs"), { desc = "Choose Theirs (all)" } },
					{ "n", "<leader>gC", actions.conflict_choose_all("base"), { desc = "Choose Base (all)" } },
					{ "n", "<leader>gA", actions.conflict_choose_all("all"), { desc = "Choose All (all)" } },
				},
			},
		})
	end,
}
