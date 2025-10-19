local map = vim.keymap.set

map("n", "<C-n>", "<cmd>Neotree toggle<CR>", { silent = true, desc = "Toggle Explorer (Neotree)" })
map("n", "<Tab>", "za", { desc = "Toggle Fold" })
map("n", "<C-.>", "5<C-w>>", { silent = true, desc = "Aumentar largura da janela" })
map("n", "<C-,>", "5<C-w><", { silent = true, desc = "Diminuir largura da janela" })
map("n", "<C-k>", "<cmd>DocsViewToggle<CR>", { silent = true, desc = "Toggle Explorer (Neotree)" })

map("n", "<leader>ff", function()
	require("telescope.builtin").find_files()
end, { desc = "Find Files" })

map("n", "<leader>lg", function()
	require("telescope.builtin").live_grep()
end, { desc = "Live Grep" })

map({ "n", "v" }, "<leader>f", function()
	require("conform").format({ lsp_fallback = true })
end, { desc = "Format Buffer" })

map("n", "<leader>zl", function()
	require("telescope.builtin").lsp_document_symbols()
end, { desc = "Symbols List" })

map("n", "gr", function()
	require("telescope.builtin").lsp_references()
end, { desc = "Goto References" })

map("n", "<leader>cc", "<cmd>CMakeConfigure<CR>", { desc = "[C]Make [C]onfigure" })
map("n", "<leader>cb", "<cmd>CMakeBuild<CR>", { desc = "[C]Make [B]uild" })
map("n", "<leader>cr", "<cmd>CMakeRun<CR>", { desc = "[C]Make [R]un" })
map("n", "<leader>cd", "<cmd>CMakeDebug<CR>", { desc = "[C]Make [D]ebug" })
map("n", "<leader>cs", "<cmd>CMakeSelectLaunchTarget<CR>", { desc = "[C]Make [S]elect Target" })
