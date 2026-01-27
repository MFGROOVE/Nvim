return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			dap.listeners.after.event_initialized["dap_arrow_keys"] = function()
				local opts = { buffer = 0, noremap = true, silent = true }
				vim.keymap.set("n", "<Down>", dap.step_over, opts)
				vim.keymap.set("n", "<Right>", dap.step_into, opts)
				vim.keymap.set("n", "<Left>", dap.step_out, opts)
				vim.keymap.set("n", "<Up>", dap.continue, opts)
			end

			vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })

			-- Standard Java Debugging
			vim.keymap.set("n", "<Leader>dc", dap.continue, { desc = "DAP: Continue/Start" })

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					local ok, jdtls = pcall(require, "jdtls")
					if ok then
						jdtls.setup_dap({ hotcodereplace = "auto" })
					end
				end,
			})

			-- Android ADB Connect
			local function debug_android()
				if vim.bo.filetype ~= "java" then
					vim.notify("Error: Open a .java file first.", vim.log.levels.ERROR)
					return
				end

				if not dap.adapters.java then
					local ok, jdtls = pcall(require, "jdtls")
					if ok then
						jdtls.setup_dap({ hotcodereplace = "auto" })
					end
				end

				local package_name = vim.fn.input("Package Name: ", "")
				if package_name == "" then
					return
				end

				local handle = io.popen("adb shell pidof " .. package_name)
				local result = handle:read("*a")
				handle:close()

				local pid = result:gsub("%s+", "")
				if pid == "" then
					vim.notify("Error: App not found (Empty PID).", vim.log.levels.ERROR)
					return
				end

				local port = math.random(50000, 60000)
				os.execute(string.format("adb forward tcp:%d jdwp:%s", port, pid))

				vim.notify("Attached: PID " .. pid .. " -> Port " .. port, vim.log.levels.INFO)

				local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
				local ok_jdtls, jdtls_dap = pcall(require, "jdtls.dap")
				if ok_jdtls and jdtls_dap.find_util_project_name then
					project_name = jdtls_dap.find_util_project_name() or project_name
				end

				dap.run({
					type = "java",
					request = "attach",
					name = "Android Attach",
					hostName = "localhost",
					port = port,
					projectName = project_name,
				})
			end

			vim.keymap.set("n", "<Leader>da", debug_android, { desc = "DAP: Debug Android" })
			vim.api.nvim_create_user_command("DebugAndroid", debug_android, {})
		end,
	},
}
