return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"stevearc/overseer.nvim",
		"nvim-neotest/neotest-python",
		"nvim-neotest/neotest-go",
		"rouge8/neotest-rust",
		"lawrence-laz/neotest-zig",
		"rcasia/neotest-java",
		"alfaix/neotest-gtest",
	},
	keys = {
		{
			"<leader>tr",
			function()
				require("neotest").run.run()
			end,
			desc = "Run nearest test",
		},
		{
			"<leader>tf",
			function()
				require("neotest").run.run(vim.fn.expand("%"))
			end,
			desc = "Run file tests",
		},
		{
			"<leader>tS",
			function()
				require("neotest").run.stop()
			end,
			desc = "Stop test",
		},
		{
			"<leader>ts",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Test Summary",
		},
		{
			"<leader>to",
			function()
				require("neotest").output.open({ enter = true })
			end,
			desc = "Show Output",
		},
		{
			"<leader>td",
			function()
				require("neotest").run.run({ strategy = "dap" })
			end,
			desc = "Debug Nearest Test",
		},
	},
	config = function()
		require("neotest").setup({
			consumers = {
				overseer = require("neotest.consumers.overseer"),
			},
			adapters = {
				require("neotest-python")({
					dap = { justMyCode = false },
				}),
				require("neotest-rust"),
				require("neotest-zig"),
				require("neotest-java")({
					ignore_wrapper = false,
				}),
				require("neotest-gtest").setup({}),
			},
		})
	end,
}
