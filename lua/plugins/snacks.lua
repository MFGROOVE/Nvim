return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		picker = { enabled = true },
		input = { enabled = true },
		dashboard = { enabled = true },
		notifier = { enabled = true },
		terminal = { enabled = true },

		indent = { enabled = true },
		scope = { enabled = true },
	},
	keys = {
		{
			"<leader>un",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>bb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
	},
}
