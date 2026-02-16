return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"jay-babu/mason-nvim-dap.nvim",
		"theHamsta/nvim-dap-virtual-text",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local last_package = ""

		local signs = {
			DapBreakpoint = { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" },
			DapBreakpointCondition = { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" },
			DapLogPoint = { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" },
			DapStopped = { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" },
		}
		for type, icon in pairs(signs) do
			vim.fn.sign_define(type, icon)
		end

		vim.api.nvim_set_hl(0, "DapBreakpoint", { ctermbg = 0, fg = "#993939", bg = "#31353f" })
		vim.api.nvim_set_hl(0, "DapStopped", { ctermbg = 0, fg = "#98c379", bg = "#31353f" })
		vim.api.nvim_set_hl(0, "DapStoppedLine", { ctermbg = 0, bg = "#31353f" })

		dapui.setup({
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.50 },
						{ id = "breakpoints", size = 0.20 },
						{ id = "stacks", size = 0.30 },
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
		})

		require("nvim-dap-virtual-text").setup({
			display_callback = function(variable, buf, stackframe, node, options)
				if options.virt_text_pos == "inline" then
					return " = " .. variable.value
				else
					return variable.name .. " = " .. variable.value
				end
			end,
		})

		require("mason-nvim-dap").setup({
			automatic_installation = true,
			ensure_installed = {
				"codelldb",
				"python",
			},
			handlers = {
				function(config)
					require("mason-nvim-dap").default_setup(config)
				end,
			},
		})

		dap.listeners.before.attach.dapui_config = function() dapui.open() end
		dap.listeners.before.launch.dapui_config = function() dapui.open() end
		dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
		dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

		dap.listeners.after.event_initialized["dap_arrow_keys"] = function()
			local opts = { buffer = 0, noremap = true, silent = true }
			vim.keymap.set("n", "<Down>", dap.step_over, opts)
			vim.keymap.set("n", "<Right>", dap.step_into, opts)
			vim.keymap.set("n", "<Left>", dap.step_out, opts)
			vim.keymap.set("n", "<Up>", dap.continue, opts)
		end

		local function debug_waydroid()
			local handle = io.popen("waydroid status | grep 'IP:' | awk '{print $2}'")
			local ip = handle:read("*a"):gsub("%s+", "")
			handle:close()

			if ip == "" then
				ip = "192.168.240.112"
			end

			local connect_out = vim.fn.system("adb connect " .. ip .. ":5555")

			if not (string.find(connect_out, "connected") or string.find(connect_out, "already connected")) then
				vim.notify("Waydroid Connection Failed.", vim.log.levels.ERROR)
				return
			end

			local prompt = last_package ~= "" and ("Package Name [" .. last_package .. "]: ") or "Package Name: "
			local input = vim.fn.input(prompt)

			if input == "" and last_package ~= "" then
				input = last_package
			elseif input ~= "" then
				last_package = input
			else
				return
			end

			local pid_output = vim.fn.system("adb shell pidof -s " .. input)
			local pid = string.match(pid_output, "%d+")

			if not pid then
				vim.notify("App not running in Waydroid: " .. input, vim.log.levels.ERROR)
				return
			end

			local port = math.random(50000, 60000)
			vim.fn.system(string.format("adb forward tcp:%d jdwp:%s", port, pid))

			vim.notify("Debugging: " .. input .. " (PID: " .. pid .. ")", vim.log.levels.INFO)

			dap.run({
				type = "java",
				request = "attach",
				name = "Waydroid Debug",
				hostName = "localhost",
				port = port,
			})
		end

		vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
		vim.keymap.set("n", "<Leader>dc", dap.continue, { desc = "Debug: Start/Continue" })
		vim.keymap.set("n", "<Leader>dx", dap.terminate, { desc = "Debug: Stop/Terminate" })
		vim.keymap.set("n", "<Leader>dt", dapui.toggle, { desc = "Debug: Toggle UI" })
		vim.keymap.set("n", "<Leader>di", function() require("dap.ui.widgets").hover() end, { desc = "Debug: Hover Info" })
		vim.keymap.set("n", "<Leader>dw", debug_waydroid, { desc = "Debug: Waydroid" })
	end,
}
