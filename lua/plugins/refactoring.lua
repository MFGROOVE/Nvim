return {
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			-- exigido no Neovim 0.12 (no 0.13 vira vim.async e deixa de ser necessário)
			"lewis6991/async.nvim",
		},
		lazy = true,
		-- Cada função retorna um operador (g@): em visual age na seleção; em normal espera
		-- um movimento/textobject (ex.: <leader>reap, <leader>rviw). Dobrar a tecla final
		-- (<leader>ree, <leader>rvv) usa a linha atual.
		keys = {
			{
				"<leader>re",
				function()
					return require("refactoring").extract_func()
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "Extract Function",
			},
			{
				"<leader>ree",
				function()
					return require("refactoring").extract_func() .. "_"
				end,
				mode = "n",
				expr = true,
				desc = "Extract Function (line)",
			},
			{
				"<leader>rf",
				function()
					return require("refactoring").extract_func_to_file()
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "Extract Function To File",
			},
			{
				"<leader>rv",
				function()
					return require("refactoring").extract_var()
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "Extract Variable",
			},
			{
				"<leader>rvv",
				function()
					return require("refactoring").extract_var() .. "_"
				end,
				mode = "n",
				expr = true,
				desc = "Extract Variable (line)",
			},
			{
				"<leader>rI",
				function()
					return require("refactoring").inline_func()
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "Inline Function",
			},
			{
				"<leader>ri",
				function()
					return require("refactoring").inline_var()
				end,
				mode = { "n", "x" },
				expr = true,
				desc = "Inline Variable",
			},
			{
				"<leader>rs",
				function()
					require("refactoring").select_refactor()
				end,
				mode = { "n", "x" },
				desc = "Select Refactor",
			},
		},
		opts = {
			show_success_message = false,
		},
	},
}
