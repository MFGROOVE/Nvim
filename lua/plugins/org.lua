return {
	{
		name = "org-workbench",
		dir = vim.fn.stdpath("config") .. "/local-plugins/org-workbench",
		ft = { "org" },
		cmd = { "OrgWorkbench" },
		keys = {
			{ "<leader>oa", "<cmd>OrgWorkbench agenda<CR>", desc = "Org agenda" },
			{ "<leader>oc", "<cmd>OrgWorkbench capture<CR>", desc = "Org capture" },
			{ "<leader>oi", "<cmd>OrgWorkbench inbox<CR>", desc = "Org inbox" },
			{ "<leader>oj", "<cmd>OrgWorkbench journal<CR>", desc = "Org journal" },
		},
		config = function()
			require("org_workbench").setup()
		end,
	},
}
