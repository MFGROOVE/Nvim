return {
  {
    "benlubas/molten-nvim",
    dependencies = { "jmbuhr/otter.nvim" },
    ft = { "quarto", "markdown", "rmd", "python", "r" },
    -- plugin remoto (python): precisa registrar os comandos :Molten*
    build = ":UpdateRemotePlugins",

    -- molten lê as globais na inicialização, então elas vão em init
    init = function()
      vim.g.molten_auto_open_output = true
      vim.g.molten_virt_text_output = false
      vim.g.molten_image_provider = "none"
    end,
  },
}
