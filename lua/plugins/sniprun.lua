return {
	{
		"michaelb/sniprun",
		build = "bash ./install.sh",
		event = "VeryLazy",
		config = function()
			require("sniprun").setup({})
		end,
	},
}
