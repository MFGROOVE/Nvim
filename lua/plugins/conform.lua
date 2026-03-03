return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>of",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = { "n", "v" },
				desc = "Format Buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				rust = { "rustfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				markdown = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				java = { "clang-format" },
			},
			default_format_opts = {
				lsp_format = "fallback",
			},
			formatters = {
				prettier = {
					prepend_args = { "--tab-width", "4" },
				},
				["clang-format"] = {
					prepend_args = { "--style={BasedOnStyle: LLVM, IndentWidth: 4, UseTab: Never}" },
				},
			},
		},
	},
}
