return {
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		lazy = true,
		keys = {
			{
				"<leader>re",
				function()
					return require("refactoring").refactor("Extract Function")
				end,
				mode = "x",
				expr = true,
				desc = "Extract Function",
			},
			{
				"<leader>rf",
				function()
					return require("refactoring").refactor("Extract Function To File")
				end,
				mode = "x",
				expr = true,
				desc = "Extract Function To File",
			},
			{
				"<leader>rv",
				function()
					return require("refactoring").refactor("Extract Variable")
				end,
				mode = "x",
				expr = true,
				desc = "Extract Variable",
			},
			{
				"<leader>rI",
				function()
					return require("refactoring").refactor("Inline Function")
				end,
				mode = "n",
				expr = true,
				desc = "Inline Function",
			},
			{
				"<leader>ri",
				function()
					return require("refactoring").refactor("Inline Variable")
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "Inline Variable",
			},
			{
				"<leader>rbb",
				function()
					return require("refactoring").refactor("Extract Block")
				end,
				mode = "n",
				expr = true,
				desc = "Extract Block",
			},
			{
				"<leader>rbf",
				function()
					return require("refactoring").refactor("Extract Block To File")
				end,
				mode = "n",
				expr = true,
				desc = "Extract Block To File",
			},
		},
		opts = {
			prompt_func_return_type = {
				go = true,
				java = true,
				cpp = true,
				c = true,
				h = true,
				hpp = true,
				cxx = true,
				rust = true,
				zig = true,
			},
			prompt_func_param_type = {
				go = true,
				java = true,
				cpp = true,
				c = true,
				h = true,
				hpp = true,
				cxx = true,
				rust = true,
				zig = true,
			},
			printf_statements = {},
			print_var_statements = {},
			show_success_message = false,
		},
	},
}
