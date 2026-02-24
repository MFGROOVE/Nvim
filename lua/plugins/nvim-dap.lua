return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"jay-babu/mason-nvim-dap.nvim",
		"theHamsta/nvim-dap-virtual-text",
	},
	config = function()
		local dap = require("dap")
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
			ensure_installed = { "codelldb", "python" },
			handlers = {
				function(config)
					require("mason-nvim-dap").default_setup(config)
				end,
			},
		})

		local function set_arrow_keys()
			vim.keymap.set("n", "<Down>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<Right>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<Left>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<Up>", dap.continue, { desc = "Debug: Continue/Play" })
		end

		local function remove_arrow_keys()
			pcall(vim.keymap.del, "n", "<Down>")
			pcall(vim.keymap.del, "n", "<Right>")
			pcall(vim.keymap.del, "n", "<Left>")
			pcall(vim.keymap.del, "n", "<Up>")
		end

		dap.listeners.after.event_initialized["dap_arrow_keys"] = set_arrow_keys
		dap.listeners.after.event_terminated["dap_arrow_keys"] = remove_arrow_keys
		dap.listeners.after.event_exited["dap_arrow_keys"] = remove_arrow_keys
		dap.listeners.after.disconnect["dap_arrow_keys"] = remove_arrow_keys

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
		vim.keymap.set("n", "<Leader>dw", debug_waydroid, { desc = "Debug: Waydroid" })
		vim.keymap.set("n", "<Leader>dx", function()
			remove_arrow_keys()
			dap.terminate()
		end, { desc = "Debug: Stop/Terminate" })
	end,
}
