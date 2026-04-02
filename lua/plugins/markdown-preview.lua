return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	build = "cd app && npx --yes yarn install",
	keys = {
		{ "<leader>op", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown Preview" },
	},
}
