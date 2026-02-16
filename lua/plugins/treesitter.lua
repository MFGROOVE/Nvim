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
				"kotlin",
			},
			sync_install = false,
			highlight = { enable = true },
			indent = { enable = true, disable = { "c", "cpp", "java" } },
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
}
