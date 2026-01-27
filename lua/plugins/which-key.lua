return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = {
		spec = {
			{ "<leader>r", group = "Run/Compiler" },
			{ "<leader>t", group = "Tests" },
			{ "<leader>d", group = "Debug" },
			{ "<leader>f", group = "Find/Files" },
			{ "<leader>g", group = "Git" },
			{ "<leader>o", group = "Organize" },
			{ "<leader>c", group = "Cmake" },
			{ "<leader>u", group = "Utility" },
			{ "<leader>s", group = "Split Window" },
			{ "<leader>p", group = "Python" },
		},
	},
}
