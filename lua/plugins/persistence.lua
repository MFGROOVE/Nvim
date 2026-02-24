return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	keys = {
		{
			"<leader>us",
			function()
				require("persistence").load()
			end,
			desc = "Restore Session",
		},
		{
			"<leader>ul",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "Restore Last Session",
		},
	},
	opts = {},
}
