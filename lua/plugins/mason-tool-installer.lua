return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event = "User MasonAttach",
		opts = {
			ensure_installed = {
				"stylua",
				"prettier",
				"black",
				"clang-format",
				"shfmt",
				"codelldb",
				"lua-language-server",
				"basedpyright",
				"clangd",
				"zls",
				"rust-analyzer",
				"cmake-language-server",
				"r-languageserver", 
			},
		},
	},
}
