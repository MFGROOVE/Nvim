return {
	{
		"jay-babu/mason-nvim-dap.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"mfussenegger/nvim-dap",
		},
		opts = {
			ensure_installed = {
				"codelldb",
				"debugpy",
				"delve",
				"java-debug-adapter",
				"java-test",
			},
			automatic_installation = true,
			handlers = {},
		},
	},
}
