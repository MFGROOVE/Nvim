return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },

		opts = {
			ensure_installed = {
				"c",
				"cpp",
				"rust",
				"zig",
				"python",
				"lua",
				"markdown",
				"vim",
				"bash",
				"asm",
				"cmake",
				"r",
				"java",
			},
			sync_install = false,
			highlight = { enable = true },
			indent = { enable = true },
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
}
