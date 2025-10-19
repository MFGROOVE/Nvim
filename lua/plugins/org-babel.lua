return {
  {
    "mrshmllow/orgmode-babel.nvim",
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-treesitter/nvim-treesitter"
    },
    config = function()
      require("orgmode-babel").setup({
        langs = { "python", "lua", "c", "cpp", "rust", "bash" },
      })
      vim.keymap.set('n', '<leader>ot', ':OrgTangle<CR>', { desc = 'Org Tangle' })
      vim.keymap.set('n', '<leader>oe', ':OrgExecute<CR>', { desc = 'Org Execute' })
    end
  },
}
