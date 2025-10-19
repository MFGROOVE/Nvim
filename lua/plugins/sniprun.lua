return {
	{
		"michaelb/sniprun",
		run = "bash ./install.sh",
		event = "VeryLazy",
		config = function()
			require("sniprun").setup({})
		end,
	},
}
