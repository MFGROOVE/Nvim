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
				"<C-k>",
				"<cmd>DocsViewToggle<cr>",
				desc = "Toggle Docs View",
			},
		},
	},
}
