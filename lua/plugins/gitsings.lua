return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, l, r, desc)
				vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
			end

			map("n", "<leader>gp", gs.preview_hunk, "Preview Git Hunk")
			map("n", "<leader>gb", function()
				gs.blame_line({ full = true })
			end, "Git Blame Line")
			map("n", "<leader>gs", gs.stage_hunk, "Stage Hunk")
			map("n", "<leader>gr", gs.reset_hunk, "Reset Hunk")
		end,
	},
}
