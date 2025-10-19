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
	},
}
