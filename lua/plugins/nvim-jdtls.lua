return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	dependencies = {
		"mfussenegger/nvim-dap",
		"saghen/blink.cmp",
	},
	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
		local bundles = {}

		local debug_jar_pattern = mason_path
			.. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
		local debug_jar_result = vim.fn.glob(debug_jar_pattern, 1)

		if debug_jar_result ~= "" then
			local debug_jar_path = vim.split(debug_jar_result, "\n")[1]
			table.insert(bundles, debug_jar_path)
		end

		local test_jar_pattern = mason_path .. "/java-test/extension/server/*.jar"
		local test_jars = vim.fn.glob(test_jar_pattern, 1)
		if test_jars ~= "" then
			for _, jar in ipairs(vim.split(test_jars, "\n")) do
				if jar ~= "" then
					table.insert(bundles, jar)
				end
			end
		end

		local on_attach = function(client, bufnr)
			local opts = { buffer = bufnr, silent = true }

			vim.keymap.set(
				"n",
				"<leader>ld",
				"<cmd>Lspsaga goto_definition<CR>",
				{ buffer = bufnr, desc = "Go to Definition", silent = true }
			)
			vim.keymap.set(
				"n",
				"<leader>lr",
				"<cmd>Lspsaga finder<CR>",
				{ buffer = bufnr, desc = "Find References", silent = true }
			)
			vim.keymap.set(
				"n",
				"<leader>ln",
				vim.lsp.buf.rename,
				{ buffer = bufnr, desc = "Rename Symbol", silent = true }
			)
			vim.keymap.set(
				{ "n", "v" },
				"<leader>la",
				"<cmd>Lspsaga code_action<CR>",
				{ buffer = bufnr, desc = "Code Action", silent = true }
			)
			vim.keymap.set(
				"n",
				"<leader>li",
				"<cmd>Lspsaga hover_doc<CR>",
				{ buffer = bufnr, desc = "Hover Documentation", silent = true }
			)
			vim.keymap.set(
				"n",
				"[d",
				vim.diagnostic.goto_prev,
				{ buffer = bufnr, desc = "Previous Diagnostic", silent = true }
			)
			vim.keymap.set(
				"n",
				"]d",
				vim.diagnostic.goto_next,
				{ buffer = bufnr, desc = "Next Diagnostic", silent = true }
			)
			if client.server_capabilities.inlayHintProvider then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			require("jdtls").setup_dap({ hotcodereplace = "auto" })
			require("jdtls.dap").setup_dap_main_class_configs()
		end

		local jdtls_bin = mason_path .. "/jdtls/bin/jdtls"
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name
		local root_dir = require("jdtls.setup").find_root({ ".git", "gradlew", "mvnw" })

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
					configuration = {
						runtimes = {
							{
								name = "JavaSE-17",
								path = "/usr/lib/jvm/java-17-openjdk/",
							},
							{
								name = "JavaSE-21",
								path = "/usr/lib/jvm/java-21-openjdk/",
							},
						},
					},
				},
			},
		}

		require("jdtls").start_or_attach(config)

		vim.keymap.set("n", "<leader>dn", function()
			require("jdtls").test_nearest_method()
		end, { desc = "Test Method" })
		vim.keymap.set("n", "<leader>dt", function()
			require("jdtls").test_class()
		end, { desc = "Test Class" })
	end,
}
