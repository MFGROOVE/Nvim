return {
	{
		"amrbashir/nvim-docs-view",
		cmd = { "DocsViewToggle" },
		opts = {
			position = "right",
			width = 60,
		},
		keys = {
			{
				"<leader>ud",
				"<cmd>DocsViewToggle<cr>",
				desc = "Docs View",
			},
		},
	},
}
