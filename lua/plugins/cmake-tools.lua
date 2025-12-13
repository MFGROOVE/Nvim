return {
	{
		"Civitasv/cmake-tools.nvim",
		ft = { "cmake", "cpp", "c" },
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		opts = {
			cmake_command = "cmake",
			cmake_build_directory = "build",
			cmake_soft_link_compile_commands = true,
		},
		keys = {
			{ "<leader>cc", "<cmd>CMakeConfigure<cr>", desc = "CMake Configure" },
			{ "<leader>cb", "<cmd>CMakeBuild<cr>", desc = "CMake Build" },
			{ "<leader>cr", "<cmd>CMakeRun<cr>", desc = "CMake Run" },
			{ "<leader>cd", "<cmd>CMakeDebug<cr>", desc = "CMake Debug" },
			{ "<leader>cs", "<cmd>CMakeSelectLaunchTarget<cr>", desc = "CMake Select Target" },
		},
	},
}
