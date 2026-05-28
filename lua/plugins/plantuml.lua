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
		init = function()
			vim.g["plantuml_previewer#plantuml_jar_path"] = vim.fn.expand("~/.local/share/plantuml/plantuml.jar")
		end,
		keys = {
			{ "<leader>oP", "<cmd>PlantumlOpen<CR>", ft = "plantuml", desc = "PlantUML Preview" },
		},
	},
}
