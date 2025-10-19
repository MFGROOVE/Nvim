
return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
  dependencies = { "mfussenegger/nvim-dap" },
  config = function()
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

    local jdtls_bin = vim.fn.stdpath('data') .. '/mason/packages/jdtls/bin/jdtls'
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
    local workspace_dir = vim.fn.stdpath('data') .. '/jdtls-workspace/' .. project_name

    local bundles = {}
    local dap_path = vim.fn.stdpath('data') .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
    for _, j in ipairs(vim.split(vim.fn.glob(dap_path), "\n")) do
      if j ~= "" then table.insert(bundles, j) end
    end

    local test_path = vim.fn.stdpath('data') .. "/mason/packages/java-test/server/*.jar"
    for _, j in ipairs(vim.split(vim.fn.glob(test_path), "\n")) do
      if j ~= "" then table.insert(bundles, j) end
    end

    local config = {
      cmd = { jdtls_bin, '-data', workspace_dir },
      root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'}),
      on_attach = on_attach,
      
      init_options = {
        bundles = bundles
      }
    }

    require('jdtls').start_or_attach(config)
  end,
}
