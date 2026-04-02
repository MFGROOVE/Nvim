return {
	{
		"aklt/plantuml-syntax",
		ft = { "plantuml" },
	},
	{
		"weirongxu/plantuml-previewer.vim",
		ft = { "plantuml" },
		dependencies = {
			"tyru/open-browser.vim",
			"aklt/plantuml-syntax",
		},
		keys = {
			{ "<leader>oP", "<cmd>PlantumlOpen<CR>", ft = "plantuml", desc = "PlantUML Preview" },
		},
	},
}
