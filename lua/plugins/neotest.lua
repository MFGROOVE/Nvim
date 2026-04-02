return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"stevearc/overseer.nvim",
		"nvim-neotest/neotest-python",
		"fredrikaverpil/neotest-golang",
		"mrcjkb/rustaceanvim",
		"lawrence-laz/neotest-zig",
		"rcasia/neotest-java",
		"alfaix/neotest-gtest",
		"orjangj/neotest-ctest",
	},
	keys = {
		{ "<leader>tr", function() require("neotest").run.run() end, desc = "Run nearest test" },
		{ "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
		{ "<leader>tA", function() require("neotest").run.run({ suite = true }) end, desc = "Run all tests" },
		{ "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop test" },
		{ "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test Summary" },
		{ "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show Output" },
		{ "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
		{ "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug Nearest Test" },
	},
	config = function()
		local java_adapter = require("neotest-java")({ ignore_wrapper = false })
		local original_is_test_file = java_adapter.is_test_file

		java_adapter.is_test_file = function(file_path)
			if not file_path:match("%.java$") then
				return false
			end
			if original_is_test_file then
				local ok, result = pcall(original_is_test_file, file_path)
				if ok then
					return result
				end
			end
			return file_path:match("[/\\]test[/\\]") ~= nil
				or file_path:match("Test%.java$") ~= nil
		end

		require("neotest").setup({
			consumers = {
				overseer = require("neotest.consumers.overseer"),
			},
			adapters = {
				require("neotest-python")({
					dap = {
						justMyCode = false,
						console = "integratedTerminal",
					},
					runner = "pytest",
				}),
				require("neotest-golang"),
				require("rustaceanvim.neotest"),
				require("neotest-zig"),
				java_adapter,
				require("neotest-ctest").setup({}),
				require("neotest-gtest").setup({
					is_test_file = function(file)
						return file:match("%.cpp$") or file:match("%.cc$") or file:match("%.cxx$")
					end,
				}),
			},
		})
	end,
}
