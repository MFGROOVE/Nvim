return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"Saghen/blink.cmp",
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local on_attach = function(client, bufnr)
				local opts = { buffer = bufnr, silent = true }

				vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>", opts)
				vim.keymap.set("n", "gr", "<cmd>Lspsaga finder<CR>", opts)
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				vim.keymap.set({ "n", "v" }, "<leader>ca", "<cmd>Lspsaga code_action<CR>", opts)
				vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end
			end

			require("mason-lspconfig").setup({
				automatic_installation = true,
				ensure_installed = {
					"lua_ls",
					"basedpyright",
					"rust_analyzer",
					"clangd",
					"zls",
					"cmake",
					"r_language_server",
					"jdtls",
				},
				handlers = {
					function(server_name)
						if server_name == "jdtls" then
							return
						end

						local server_opts = { on_attach = on_attach, capabilities = capabilities }
						if server_name == "rust_analyzer" then
							server_opts.settings = {
								["rust-analyzer"] = {
									inlayHints = { typeHints = { enable = true }, parameterHints = { enable = true } },
									cargo = { allFeatures = true },
									check = { command = "clippy", onSave = true, extraArgs = { "--no-deps" } },
								},
							}
						elseif server_name == "lua_ls" then
							server_opts.settings = { Lua = { diagnostics = { globals = { "vim" } } } }
						elseif server_name == "r_language_server" then
							server_opts.filetypes = { "r", "rmd" }
							server_opts.root_dir =
								lspconfig.util.root_pattern(".Rproj", ".git", ".here", "_quarto.yml", "_bookdown.yml")
						end

						lspconfig[server_name].setup(server_opts)
					end,
				},
			})
		end,
	},
}
