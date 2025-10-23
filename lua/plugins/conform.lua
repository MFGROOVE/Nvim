return {
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "black" },
				rust = { "rustfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				markdown = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
                java = {"clang-format"},
			},
		},
	},
}
