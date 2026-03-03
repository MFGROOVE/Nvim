return {
	"jake-stewart/multicursor.nvim",
	branch = "1.0",
	keys = {
		{ "<leader>mn", mode = { "n", "x" }, desc = "Add cursor next match" },
		{ "<leader>mN", mode = { "n", "x" }, desc = "Add cursor prev match" },
		{ "<leader>ms", mode = { "n", "x" }, desc = "Skip next match" },
		{ "<leader>mS", mode = { "n", "x" }, desc = "Skip prev match" },
		{ "<leader>ma", mode = { "n", "x" }, desc = "Add cursors to all matches" },
		{ "<leader>mj", mode = { "n", "x" }, desc = "Add cursor below" },
		{ "<leader>mk", mode = { "n", "x" }, desc = "Add cursor above" },
		{ "<leader>md", mode = { "n", "x" }, desc = "Delete cursor" },
		{ "<leader>mc", mode = { "n", "x" }, desc = "Clear cursors" },
		{ "<leader>mt", mode = { "n", "x" }, desc = "Toggle cursors" },
		{ "<leader>mr", mode = { "n", "x" }, desc = "Restore cursors" },
		{ "<leader>m]", mode = { "n", "x" }, desc = "Next cursor" },
		{ "<leader>m[", mode = { "n", "x" }, desc = "Prev cursor" },
		{ "<leader>ml", mode = "n", desc = "Align cursors" },
		{ "<leader>mx", mode = "x", desc = "Split cursors by regex" },
	},
	config = function()
		local mc = require("multicursor-nvim")
		mc.setup()

		local set = vim.keymap.set

		set({ "n", "x" }, "<leader>mn", function()
			mc.matchAddCursor(1)
		end, { desc = "Add cursor next match" })
		set({ "n", "x" }, "<leader>mN", function()
			mc.matchAddCursor(-1)
		end, { desc = "Add cursor prev match" })
		set({ "n", "x" }, "<leader>ms", function()
			mc.matchSkipCursor(1)
		end, { desc = "Skip next match" })
		set({ "n", "x" }, "<leader>mS", function()
			mc.matchSkipCursor(-1)
		end, { desc = "Skip prev match" })
		set({ "n", "x" }, "<leader>ma", mc.matchAllAddCursors, { desc = "Add cursors to all matches" })
		set({ "n", "x" }, "<leader>mj", function()
			mc.lineAddCursor(1)
		end, { desc = "Add cursor below" })
		set({ "n", "x" }, "<leader>mk", function()
			mc.lineAddCursor(-1)
		end, { desc = "Add cursor above" })
		set({ "n", "x" }, "<leader>md", mc.deleteCursor, { desc = "Delete cursor" })
		set({ "n", "x" }, "<leader>mc", mc.clearCursors, { desc = "Clear cursors" })
		set({ "n", "x" }, "<leader>mt", mc.toggleCursor, { desc = "Toggle cursors" })
		set({ "n", "x" }, "<leader>mr", mc.restoreCursors, { desc = "Restore cursors" })
		set({ "n", "x" }, "<leader>m]", mc.nextCursor, { desc = "Next cursor" })
		set({ "n", "x" }, "<leader>m[", mc.prevCursor, { desc = "Prev cursor" })
		set("n", "<leader>ml", mc.alignCursors, { desc = "Align cursors" })
		set("x", "<leader>mx", mc.splitCursors, { desc = "Split cursors by regex" })

		set("n", "<c-leftmouse>", mc.handleMouse, {})
		set("n", "<c-leftdrag>", mc.handleMouseDrag, {})
		set("n", "<c-leftrelease>", mc.handleMouseRelease, {})

		set("n", "<esc>", function()
			if not mc.cursorsEnabled() then
				mc.enableCursors()
			elseif mc.hasCursors() then
				mc.clearCursors()
			else
				vim.cmd("nohlsearch")
			end
		end)
	end,
}
