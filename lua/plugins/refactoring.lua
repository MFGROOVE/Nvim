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
					require("refactoring").refactor("Extract Function")
				end,
				mode = "x",
				desc = "Extract Function",
			},
			{
				"<leader>rf",
				function()
					require("refactoring").refactor("Extract Function To File")
				end,
				mode = "x",
				desc = "Extract Function To File",
			},
			{
				"<leader>rv",
				function()
					require("refactoring").refactor("Extract Variable")
				end,
				mode = "x",
				desc = "Extract Variable",
			},
			{
				"<leader>rI",
				function()
					require("refactoring").refactor("Inline Function")
				end,
				mode = "n",
				desc = "Inline Function",
			},
			{
				"<leader>ri",
				function()
					require("refactoring").refactor("Inline Variable")
				end,
				mode = { "n", "x" },
				desc = "Inline Variable",
			},
			{
				"<leader>rbb",
				function()
					require("refactoring").refactor("Extract Block")
				end,
				mode = "n",
				desc = "Extract Block",
			},
			{
				"<leader>rbf",
				function()
					require("refactoring").refactor("Extract Block To File")
				end,
				mode = "n",
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
			show_success_message = false, -- shows a message with information about the refactor on success
			-- i.e. [Refactor] Inlined 3 variable occurrences
		},
	},
}
