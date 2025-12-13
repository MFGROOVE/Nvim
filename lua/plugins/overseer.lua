return {
	"stevearc/overseer.nvim",
	opts = {
		templates = { "builtin", "vscode" },

		task_list = {
			direction = "bottom",
			min_height = 25,
			max_height = 25,
			default_detail = 1,
			bindings = {
				["?"] = "ShowHelp",
				["<CR>"] = "RunAction",
				["e"] = "Edit",
				["o"] = "Open",
				["<C-v>"] = "OpenVsplit",
				["<C-s>"] = "OpenSplit",
				["<C-f>"] = "OpenFloat",
				["<C-q>"] = "OpenQuickFix",
				["p"] = "TogglePreview",
				["<C-l>"] = "IncreaseDetail",
				["<C-h>"] = "DecreaseDetail",
				["L"] = "IncreaseAllDetail",
				["H"] = "DecreaseAllDetail",
				["["] = "DecreaseWidth",
				["]"] = "IncreaseWidth",
				["{"] = "PrevTask",
				["}"] = "NextTask",
				["<C-k>"] = "ScrollOutputUp",
				["<C-j>"] = "ScrollOutputDown",
				["q"] = "Close",
			},
		},

		-- Task selection menu configuration
		task_launcher = {
			bindings = {
				i = {
					["<CR>"] = "Submit",
					["<C-s>"] = "Submit",
					["<C-c>"] = "Cancel",
				},
				n = {
					["<CR>"] = "Submit",
					["<C-s>"] = "Submit",
					["q"] = "Cancel",
					["?"] = "ShowHelp",
				},
			},
		},

		-- Disable numbers as shortcuts
		form = {
			border = "rounded",
			win_opts = {
				winblend = 0,
			},
		},
	},

	keys = {
		{ "<leader>rr", "<cmd>OverseerRun<CR>", desc = "Run Project/OverseerRun" },
		{ "<leader>rl", "<cmd>OverseerToggle<CR>", desc = "Task List/OverseerToggle" },
		{ "<leader>ra", "<cmd>OverseerQuickAction<CR>", desc = "Task Action/OverseerQuickAction" },
		{ "<leader>rb", "<cmd>OverseerBuild<CR>", desc = "Run Default Task/OverseerBuild" },
	},
}
