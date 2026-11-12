return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"saghen/blink.cmp",
	},
	config = function()
		local capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			require("blink.cmp").get_lsp_capabilities()
		)

		vim.lsp.config("*", { capabilities = capabilities })

		-- Substitui o antigo on_attach: vale para todo servidor (inclusive jdtls e rustaceanvim)
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
			callback = function(args)
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if not client then
					return
				end
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
				end
			end,
		})

		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--completion-style=detailed",
				"--header-insertion=iwyu",
				"--clang-tidy",
			},
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					completion = {
						callSnippet = "Replace",
						displayContext = 1,
					},
				},
			},
		})

		vim.lsp.config("basedpyright", {
			settings = {
				basedpyright = {
					analysis = {
						typeCheckingMode = "standard",
						autoImportCompletions = true,
					},
				},
			},
		})

		vim.lsp.config("zls", {
			settings = {
				zls = {
					enable_argument_placeholders = true,
					completion_parse_comments = true,
				},
			},
		})

		vim.lsp.config("r_language_server", {
			filetypes = { "r", "rmd" },
			root_dir = function(bufnr, on_dir)
				on_dir(vim.fs.root(bufnr, { ".Rproj", ".git", ".here" }) or vim.uv.os_homedir())
			end,
		})

		vim.lsp.config("kotlin_language_server", {
			cmd_env = {
				JAVA_HOME = "/usr/lib/jvm/java-21-openjdk",
				PATH = "/usr/lib/jvm/java-21-openjdk/bin:" .. vim.env.PATH,
			},
			root_markers = {
				"settings.gradle",
				"settings.gradle.kts",
				"build.gradle",
				"build.gradle.kts",
				".git",
			},
			init_options = {
				storagePath = vim.fn.stdpath("cache") .. "/kotlin-language-server",
				externalSources = { useKlsScheme = true },
			},
		})

		-- mason-lspconfig v2: chama vim.lsp.enable() para cada servidor instalado.
		-- jdtls -> nvim-jdtls.lua; rust_analyzer -> rustaceanvim.lua;
		-- stylua roda via conform; neocmake duplicaria o cmake-language-server.
		require("mason-lspconfig").setup({
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
			automatic_enable = {
				exclude = { "jdtls", "rust_analyzer", "stylua", "neocmake" },
			},
		})
	end,
}
