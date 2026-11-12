return {
	{
		"jay-babu/mason-nvim-dap.nvim",
		lazy = true,
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		opts = {
			-- nomes de adapter do nvim-dap, não de pacote do mason
			-- (python -> debugpy, javadbg -> java-debug-adapter, javatest -> java-test)
			ensure_installed = {
				"codelldb",
				"python",
				"delve",
				"javadbg",
				"javatest",
			},
			automatic_installation = true,
			handlers = {},
		},
	},
}
