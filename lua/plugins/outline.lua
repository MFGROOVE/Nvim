return {
	"hedyhli/outline.nvim",
	cmd = { "Outline", "OutlineOpen" },
	keys = {
		{ "<leader>oo", "<cmd>Outline<CR>", desc = "Toggle Symbols Outline" },
	},
	opts = {
		outline_window = {
			position = "left",
			width = 30,
		},
	},
}
