return {
	{
		"rcarriga/nvim-dap-ui",
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		config = function()
			require("dapui").setup()
			local dapui = require("dapui")
			vim.keymap.set("n", "<Leader>db", function()
				dapui.toggle()
			end, { desc = "DAP UI: Toggle" })

			dapui.setup({
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.40 },
							{ id = "breakpoints", size = 0.20 },
							{ id = "stacks", size = 0.20 },
							{ id = "watches", size = 0.20 },
						},
						size = 40,
						position = "left",
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 },
						},
						size = 10,
						position = "bottom",
					},
				},
				floating = {
					max_height = nil,
					max_width = nil,
					border = "single",
				},
				render = {
					max_type_length = nil,
				},
			})
		end,
	},
}
