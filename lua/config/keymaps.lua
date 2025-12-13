local map = vim.keymap.set
map("n", "<C-n>", "<cmd>Neotree toggle<CR>", { silent = true, desc = "Toggle Explorer (Neotree)" })
map("n", "<Tab>", "za", { desc = "Toggle Fold" })
map("n", "<C-.>", "5<C-w>>", { silent = true, desc = "Aumentar largura da janela" })
map("n", "<C-,>", "5<C-w><", { silent = true, desc = "Diminuir largura da janela" })
