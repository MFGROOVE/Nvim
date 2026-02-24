return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	dependencies = {
		"saghen/blink.cmp",
	},
	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
		local bundles = {}
		local last_package = ""

		local debug_jar_pattern = mason_path
			.. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
		local debug_jar = vim.fn.glob(debug_jar_pattern, 1)
		if debug_jar ~= "" then
			local jar_path = vim.split(debug_jar, "\n")[1]
			table.insert(bundles, jar_path)
		else
			vim.notify(
				"[JDTLS] Debug JAR não encontrado! Execute :MasonInstall java-debug-adapter",
				vim.log.levels.ERROR
			)
		end

		local test_jars_pattern = mason_path .. "/java-test/extension/server/*.jar"
		local test_jars = vim.fn.glob(test_jars_pattern, 1)
		if test_jars ~= "" then
			for _, jar in ipairs(vim.split(test_jars, "\n")) do
				if jar ~= "" then
					table.insert(bundles, jar)
				end
			end
		else
			vim.notify("[JDTLS] JARs de teste não encontrados! Execute :MasonInstall java-test", vim.log.levels.ERROR)
		end

		local on_attach = function(client, bufnr)
			local dap = require("dap")
			local dapui = require("dapui")

			local opts = function(description)
				return { buffer = bufnr, silent = true, desc = description }
			end

			vim.keymap.set("n", "<leader>ld", "<cmd>Lspsaga goto_definition<CR>", opts("LSP: Goto Definition"))
			vim.keymap.set("n", "<leader>lr", "<cmd>Lspsaga finder<CR>", opts("LSP: Finder (Refs/Def)"))
			vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, opts("LSP: Rename"))
			vim.keymap.set({ "n", "v" }, "<leader>la", "<cmd>Lspsaga code_action<CR>", opts("LSP: Code Action"))
			vim.keymap.set("n", "<leader>li", "<cmd>Lspsaga hover_doc<CR>", opts("LSP: Hover Doc"))
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Diagnostic: Prev"))
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Diagnostic: Next"))

			if client.server_capabilities.inlayHintProvider then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			if client.server_capabilities.codeLensProvider then
				vim.lsp.codelens.refresh()
				vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
					buffer = bufnr,
					callback = vim.lsp.codelens.refresh,
				})
			end

			require("jdtls").setup_dap({ hotcodereplace = "auto" })
			require("jdtls.dap").setup_dap_main_class_configs()

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

			vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, opts("Debug: Toggle Breakpoint"))
			vim.keymap.set("n", "<Leader>dc", dap.continue, opts("Debug: Start/Continue"))
			vim.keymap.set("n", "<Leader>dx", dap.terminate, opts("Debug: Stop/Terminate"))
			vim.keymap.set("n", "<Leader>dt", dapui.toggle, opts("Debug: Toggle UI"))
			vim.keymap.set("n", "<Leader>di", function()
				require("dap.ui.widgets").hover()
			end, opts("Debug: Hover Info"))
			vim.keymap.set("n", "<Leader>dw", debug_waydroid, opts("Debug: Waydroid Attach"))

			vim.keymap.set("n", "<leader>tm", require("jdtls").test_nearest_method, opts("Java: Test Nearest Method"))
			vim.keymap.set("n", "<leader>tc", require("jdtls").test_class, opts("Java: Test Class"))
			vim.keymap.set("n", "<leader>tr", function()
				require("jdtls").test_nearest_method({ run = true })
			end, opts("Java: Run Nearest Test"))
		end

		local jdtls_bin = mason_path .. "/jdtls/bin/jdtls"
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

		local root_dir = require("jdtls.setup").find_root({ "build.gradle", "pom.xml", "gradlew", "mvnw", ".git" })

		local config = {
			capabilities = capabilities,
			cmd = { jdtls_bin, "-data", workspace_dir },
			root_dir = root_dir,
			on_attach = on_attach,
			init_options = {
				bundles = bundles,
				extendedClientCapabilities = require("jdtls").extendedClientCapabilities,
			},
			settings = {
				java = {
					testCodeLens = { enabled = true },
					referencesCodeLens = { enabled = true },
					implementationsCodeLens = { enabled = true },
					configuration = {
						runtimes = {
							{ name = "JavaSE-17", path = "/usr/lib/jvm/java-17-openjdk/" },
							{ name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk/" },
						},
					},
				},
			},
		}

		require("jdtls").start_or_attach(config)
	end,
}
