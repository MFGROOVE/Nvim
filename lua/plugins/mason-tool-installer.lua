return {
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },

		opts = {
			ensure_installed = {
				"stylua",
				"prettier",
				"black",
				"clang-format",
				"shfmt",
			},
			run_on_start = true,
			debounce_hours = nil,
			start_delay = 2000,
		},
	},
}
