return {
	"ahmedkhalf/project.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	lazy = false,
	keys = {
		{ "<leader>fp", "<cmd>Telescope projects<CR>", desc = "Find Projects" },
	},
	config = function()
		require("project_nvim").setup({
			manual_mode = false,
			detection_methods = { "pattern" },

			patterns = {
				".git",
				"_darcs",
				".hg",
				".bzr",
				".svn",

				-- C / C++ / CMake
				"CMakeLists.txt",
				"Makefile",
				"compile_commands.json",

				-- Rust
				"Cargo.toml",

				-- Zig
				"build.zig",
				"zls.json",

				-- Java
				"pom.xml", -- Maven
				"build.gradle", -- Gradle

				-- Python
				"venv",
				".venv",
			},

			show_hidden = false,
			silent_chdir = true,
			ignore_lsp = {},
			datapath = vim.fn.stdpath("data"),
		})

		require("telescope").load_extension("projects")
	end,
}
