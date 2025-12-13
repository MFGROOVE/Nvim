return {
	{
		"mfussenegger/nvim-dap",
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dap.listeners.before.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			dap.listeners.after.event_initialized["dap_arrow_keys"] = function()
				local opts = { buffer = 0, noremap = true, silent = true }
				vim.keymap.set("n", "<Down>", function()
					dap.step_over()
				end, opts)
				vim.keymap.set("n", "<Right>", function()
					dap.step_into()
				end, opts)
				vim.keymap.set("n", "<Left>", function()
					dap.step_out()
				end, opts)
				vim.keymap.set("n", "<Up>", function()
					dap.continue()
				end, opts)
			end

			vim.keymap.set("n", "<Leader>db", function()
				dap.toggle_breakpoint()
			end, { desc = "DAP: Set Breakpoint" })
			vim.keymap.set("n", "<Leader>dr", function()
				dap.repl.open()
			end, { desc = "DAP: Open REPL" })
		end,
	},
}
