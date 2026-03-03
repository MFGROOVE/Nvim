return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"saghen/blink.cmp",
	},
	config = function()
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")

		local default_capabilities = vim.lsp.protocol.make_client_capabilities()
		local capabilities =
			vim.tbl_deep_extend("force", default_capabilities, require("blink.cmp").get_lsp_capabilities())

		local on_attach = function(client, bufnr)
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
			if client.server_capabilities.inlayHintProvider then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end
		end

		require("mason").setup()

		mason_lspconfig.setup({
			automatic_installation = false,
			ensure_installed = {
				"lua_ls",
				"basedpyright",
				"rust_analyzer",
				"clangd",
				"zls",
				"cmake",
				"r_language_server",
				"kotlin_language_server",
				"lemminx",
			},
			handlers = {
				["jdtls"] = function()
					lspconfig.jdtls.setup({
						autostart = false,
						filetypes = {},
					})
				end,

				function(server_name)
					if server_name == "stylua" or server_name == "jdtls" then
						return
					end

					local server_opts = { on_attach = on_attach, capabilities = capabilities }

					if server_name == "clangd" then
						server_opts.cmd = {
							"clangd",
							"--completion-style=detailed",
							"--header-insertion=iwyu",
							"--clang-tidy",
						}
					elseif server_name == "rust_analyzer" then
						server_opts.settings = {
							["rust-analyzer"] = {
								check = { command = "clippy" },
								completion = {
									fullFunctionSignatures = { enable = true },
									postfix = { enable = true },
								},
							},
						}
					elseif server_name == "lua_ls" then
						server_opts.settings = {
							Lua = {
								diagnostics = { globals = { "vim" } },
								completion = {
									callSnippet = "Replace",
									displayContext = 1,
								},
							},
						}
					elseif server_name == "basedpyright" then
						server_opts.settings = {
							basedpyright = {
								analysis = {
									typeCheckingMode = "standard",
									autoImportCompletions = true,
								},
							},
						}
					elseif server_name == "zls" then
						server_opts.settings = {
							zls = {
								enable_argument_placeholders = true,
								completion_parse_comments = true,
							},
						}
					elseif server_name == "r_language_server" then
						server_opts.filetypes = { "r", "rmd" }
						server_opts.root_dir = lspconfig.util.root_pattern(".Rproj", ".git", ".here")
					elseif server_name == "kotlin_language_server" then
						server_opts.cmd_env = {
							JAVA_HOME = "/usr/lib/jvm/java-21-openjdk",
							PATH = "/usr/lib/jvm/java-21-openjdk/bin:" .. vim.env.PATH,
						}

						server_opts.root_dir = lspconfig.util.root_pattern(
							"settings.gradle",
							"settings.gradle.kts",
							"build.gradle",
							"build.gradle.kts",
							".git"
						)

						server_opts.init_options = {
							storagePath = vim.fn.stdpath("cache") .. "/kotlin-language-server",
							externalSources = { useKlsScheme = true },
						}
					end

					lspconfig[server_name].setup(server_opts)
				end,
			},
		})
	end,
}
