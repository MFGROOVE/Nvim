# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Neovim configuration using [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. All plugin specs live in `lua/plugins/` and are auto-imported via `{ import = "plugins" }`.

- `init.lua` — bootstrap lazy.nvim, set leader key (`\`), load core config modules, register plugins
- `lua/config/options.lua` — vim options, indentation, folding, and diagnostic config
- `lua/config/keymaps.lua` — global keymaps (not plugin-specific)
- `lua/plugins/*.lua` — one file per plugin or plugin group; each returns a lazy.nvim spec table

## Architecture & Key Conventions

### Plugin file structure
Each file in `lua/plugins/` returns a lazy.nvim spec. Plugin-specific keymaps go inside the spec's `keys` or `config` fields, not in `lua/config/keymaps.lua`. Plugins are lazy-loaded via `keys`, `cmd`, `ft`, or `event` triggers.

### Indentation
4-space indentation everywhere (`expandtab`, `tabstop=4`, `shiftwidth=4`). Uses `autoindent` (not `smartindent` — it conflicts with `cindent` for C switch-case). `cinoptions = "g0"` places C++ access specifiers at class level. Formatters (prettier, clang-format) are configured with `IndentWidth: 4` via `prepend_args` in conform.

### LSP setup
LSP is managed by mason + mason-lspconfig (`lua/plugins/nvim-lspconfig.lua`). The `on_attach` callback **disables** LSP formatting — formatting is handled exclusively by conform.nvim. Inlay hints are enabled by default when the server supports them.

Per-server detailed completion settings:
- **clangd** — `--completion-style=detailed`, `--header-insertion=iwyu`, `--clang-tidy`
- **rust_analyzer** — `fullFunctionSignatures`, postfix completions, clippy
- **lua_ls** — `callSnippet = "Replace"`, `displayContext = 1`
- **basedpyright** — `typeCheckingMode = "standard"`, `autoImportCompletions`
- **zls** — `enable_argument_placeholders`, `completion_parse_comments`
- **kotlin_language_server** — uses Java 21 from `/usr/lib/jvm/java-21-openjdk`

**Java is a special case**: `jdtls` is excluded from mason-lspconfig handlers and configured separately via `lua/plugins/nvim-jdtls.lua` (uses `mfussenegger/nvim-jdtls`). The mason handler sets `jdtls` to `autostart = false` with empty filetypes.

### Completion
`blink.cmp` (`lua/plugins/blink_cmp.lua`) with `luasnip` preset for snippets. Keymap preset: `enter` (Enter to accept). Completion menu shows `kind_icon`, `label`, and `kind` columns.

Key bindings: `<Tab>`/`<S-Tab>` navigate menu, `<C-l>`/`<C-h>` jump snippet placeholders, `<C-s>` show signature, `<C-k>` show/hide documentation.

### Custom snippets (LuaSnip)
`lua/plugins/luasnip.lua` — LuaSnip v2 with `history = true`. Uses `delete_check_events` and `region_check_events` to properly clean up stale snippet sessions. Defines a `pack` snippet for Java/Kotlin that auto-generates `package` declarations from file path.

### Formatting
`conform.nvim` (`lua/plugins/conform.lua`) runs on `BufWritePre`. Manual format: `<leader>of`.

| Filetype | Formatter |
|---|---|
| Lua | stylua |
| Python | isort, black |
| Rust | rustfmt |
| C/C++ | clang-format (IndentWidth: 4) |
| Java | clang-format (IndentWidth: 4) |
| Markdown/JSON/YAML/HTML/CSS | prettier (tab-width: 4) |

### Treesitter
`lua/plugins/treesitter.lua` tracks the **`main` branch** of nvim-treesitter (and nvim-treesitter-textobjects), which uses the new API: parsers are installed via `require("nvim-treesitter").install({...})` (not the legacy `nvim-treesitter.configs` `setup{}`/`ensure_installed`), highlighting is started per-buffer with a `FileType` autocmd calling `vim.treesitter.start`, and textobject move/select calls take an explicit `"textobjects"` query group argument.

Because the `main` branch dropped `nvim-treesitter.parsers.ft_to_lang` (and friends) that other plugins — notably Telescope's `utils.lua`, which captures a stale `ts_parsers` reference — still call, the `config` function installs a **compatibility shim**: it monkey-patches `ft_to_lang`, `get_parser`, `get_parser_configs`, and `available_parsers` back onto the parsers module, and re-applies them on `User LazyLoad` and `BufWinEnter` to cover plugins that `require` it later. If Telescope or other consumers start erroring about missing `ft_to_lang`/parser functions, this shim is the place to look.

### Testing (neotest)
`lua/plugins/neotest.lua` with adapters: Python, Go, Rust (rustaceanvim), Zig, Java (neotest-java), C++ (neotest-gtest), CMake/CTest (neotest-ctest). Integrates with overseer.nvim for task running.

The Java adapter has a pcall-wrapped `is_test_file` fallback that matches `src/test/` paths and `*Test.java` filenames when neotest-java's built-in detection fails.

Key bindings: `<leader>tr` (run nearest), `<leader>tf` (run file), `<leader>tA` (run all), `<leader>td` (debug nearest), `<leader>ts` (summary), `<leader>to` (output).

### Debugging (nvim-dap)
`lua/plugins/nvim-dap.lua` — loads nvim-dap-ui as a dependency. During an active debug session, arrow keys are remapped: Up=continue, Down=step over, Right=step into, Left=step out. They revert when the session ends.

DAP adapters installed via mason: `codelldb`, `python`. Includes `<leader>dw` to attach to Android apps running in Waydroid via ADB/JDWP.

Key bindings: `<leader>db` (breakpoint), `<leader>dc` (continue), `<leader>dx` (terminate), `<leader>dt` (toggle UI), `<leader>dh` (hover info).

### LSP UI (lspsaga)
`lua/plugins/lspsaga.lua` — loads on `LspAttach`. Provides: `<leader>ld` (goto definition), `<leader>lr` (finder), `<leader>ln` (rename), `<leader>la` (code action), `<leader>li` (hover doc), `[d`/`]d` (diagnostic jump).

### Multicursor
`lua/plugins/multicursor.lua` — `jake-stewart/multicursor.nvim`. All keymaps under `<leader>m` prefix. Escape clears cursors or disables highlight search. Does NOT use `addKeymapLayer` (it blocks which-key popup).

### Refactoring
`lua/plugins/refactoring.lua` — `ThePrimeagen/refactoring.nvim`. All key entries use `expr = true` because `refactor()` returns an operator string (`"g@"`). Keymaps under `<leader>r` prefix.

### Task runner (overseer)
`lua/plugins/overseer.lua` — supports builtin and vscode task templates. Keymaps: `<leader>xr` (run), `<leader>xl` (task list), `<leader>xa` (quick action), `<leader>xb` (build).

### CMake
`lua/plugins/cmake-tools.lua` — loaded for cmake/cpp/c filetypes. Keymaps: `<leader>cc` (configure), `<leader>cb` (build), `<leader>cr` (run), `<leader>cd` (debug).

## Keymap Groups (which-key)

| Prefix | Group |
|---|---|
| `<leader>c` | Cmake |
| `<leader>d` | Debug |
| `<leader>f` | Find/Files |
| `<leader>g` | Git |
| `<leader>l` | LSP |
| `<leader>m` | Multicursor |
| `<leader>o` | Organize |
| `<leader>p` | Python |
| `<leader>q` | Trouble/Quickfix |
| `<leader>r` | Refactor |
| `<leader>s` | Split Window |
| `<leader>t` | Tests |
| `<leader>u` | Utility |
| `<leader>x` | Run/Compiler |

## UI & Appearance

- **Colorscheme**: tokyonight-night
- **Statusline**: lualine (tokyonight theme, global statusline)
- **File explorer**: neo-tree (`<C-n>` to toggle)
- **Notifications**: noice.nvim + nvim-notify
- **Dashboard/Picker**: snacks.nvim (`<leader>bb` for buffers, `<leader>un` for notification history)
- **Diagnostics**: Nerd Font icons (󰅚 error, 󰀪 warn, 󰌶 hint, 󰋽 info), inline virtual text with `●` prefix
- **Folds**: treesitter-based (`foldexpr`), fold_line.nvim for visual guides, `<Tab>` toggles folds
- **Git signs**: gitsigns.nvim (`lua/plugins/gitsings.lua`) — `<leader>gp` (preview), `<leader>gb` (blame), `<leader>gs` (stage), `<leader>gr` (reset)

## Plugin Management

Restart Neovim to apply changes. Useful commands:
- `:Lazy` / `:Lazy sync` — plugin manager
- `:Mason` — LSP servers, formatters, DAP adapters
- `:ConformInfo` — formatter status
- `:TSUpdate` — treesitter parsers (legacy command; on the `main` branch parsers are managed via `require("nvim-treesitter").install` and `:TSInstall`/`:TSUpdate` from the new API)

## Known Issues

- `lua/plugins/gitsings.lua` — filename typo (should be `gitsigns.lua`), but functional
- `lua/plugins/nvim-jdtls.lua` — may need verification; jdtls setup depends on this file being correct
- `lua/plugins/treesitter.lua` — the `config` function contains leftover debug logging that appends to `/tmp/nvim-shim-debug.log` on every startup; safe to remove once the parser shim is confirmed stable
