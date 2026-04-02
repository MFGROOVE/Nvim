return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
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
			indent = { enable = true },
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)

			local move = require("nvim-treesitter-textobjects.move")
			local select = require("nvim-treesitter-textobjects.select")
			local swap = require("nvim-treesitter-textobjects.swap")

			local map = vim.keymap.set

			map({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.inner") end, { desc = "Next parameter" })
			map({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.inner") end, { desc = "Previous parameter" })
			map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer") end, { desc = "Next function" })
			map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer") end, { desc = "Previous function" })
			map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer") end, { desc = "Next class" })
			map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer") end, { desc = "Previous class" })

			map({ "x", "o" }, "af", function() select.select_textobject("@function.outer") end, { desc = "Around function" })
			map({ "x", "o" }, "if", function() select.select_textobject("@function.inner") end, { desc = "Inner function" })
			map({ "x", "o" }, "ac", function() select.select_textobject("@class.outer") end, { desc = "Around class" })
			map({ "x", "o" }, "ic", function() select.select_textobject("@class.inner") end, { desc = "Inner class" })
			map({ "x", "o" }, "aa", function() select.select_textobject("@parameter.outer") end, { desc = "Around parameter" })
			map({ "x", "o" }, "ia", function() select.select_textobject("@parameter.inner") end, { desc = "Inner parameter" })

			map("n", "<leader>a", function() swap.swap_next("@parameter.inner") end, { desc = "Swap parameter next" })
			map("n", "<leader>A", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap parameter previous" })
		end,
	},
}
