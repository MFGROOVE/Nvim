return {
	"mrcjkb/rustaceanvim",
	-- rustaceanvim já é lazy por filetype; o README pede para não usar lazy loading
	lazy = false,
	init = function()
		vim.g.rustaceanvim = function()
			return {
				server = {
					capabilities = require("blink.cmp").get_lsp_capabilities(),
					default_settings = {
						["rust-analyzer"] = {
							check = { command = "clippy" },
							completion = {
								fullFunctionSignatures = { enable = true },
								postfix = { enable = true },
							},
						},
					},
				},
			}
		end
	end,
}
