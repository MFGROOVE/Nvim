return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"Saghen/blink.cmp",
	},
	config = function()
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		local on_attach = function(client, bufnr)
			local opts = { buffer = bufnr, silent = true }
			vim.keymap.set("n", "<leader>ld", "<cmd>Lspsaga goto_definition<CR>", opts)
			vim.keymap.set("n", "<leader>lr", "<cmd>Lspsaga finder<CR>", opts)
			vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, opts)
			vim.keymap.set({ "n", "v" }, "<leader>la", "<cmd>Lspsaga code_action<CR>", opts)
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
			vim.keymap.set("n", "<leader>li", "<cmd>Lspsaga hover_doc<CR>", opts)

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

					if server_name == "rust_analyzer" then
						server_opts.settings = { ["rust-analyzer"] = { check = { command = "clippy" } } }
					elseif server_name == "lua_ls" then
						server_opts.settings = { Lua = { diagnostics = { globals = { "vim" } } } }
					elseif server_name == "r_language_server" then
						server_opts.filetypes = { "r", "rmd" }
						server_opts.root_dir = lspconfig.util.root_pattern(".Rproj", ".git", ".here")
					elseif server_name == "kotlin_language_server" then
						server_opts.root_dir = lspconfig.util.root_pattern(
							"settings.gradle",
							"settings.gradle.kts",
							"build.gradle",
							"build.gradle.kts"
						)
					end

					lspconfig[server_name].setup(server_opts)
				end,
			},
		})
	end,
}
