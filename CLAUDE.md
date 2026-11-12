# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Neovim configuration using [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. All plugin specs live in `lua/plugins/` and are auto-imported via `{ import = "plugins" }`.

- `init.lua` — bootstrap lazy.nvim, set leader key (`\`), load core config modules, register plugins
- `lua/config/options.lua` — vim options, indentation, folding, diagnostic config, and two global autocmds
- `lua/config/keymaps.lua` — global keymaps (not plugin-specific)
- `lua/plugins/*.lua` — one file per plugin or plugin group; each returns a lazy.nvim spec table

## Working in this repo

There is no build, test, or lint suite. Changes are applied by restarting Neovim.

```bash
# Syntax-check a single spec without launching the UI
nvim --headless -c 'luafile lua/plugins/treesitter.lua' -c 'qa'

# Start clean and watch for load errors (lazy.nvim reports failing specs on startup)
nvim --headless '+Lazy! sync' +qa

# Format Lua (stylua is the configured formatter; there is no stylua.toml,
# so it uses defaults — tab indentation, which is why most files are tab-indented)
stylua lua/
```

Useful in-editor commands: `:Lazy` / `:Lazy sync`, `:Mason`, `:ConformInfo`, `:checkhealth`.

## Architecture & Key Conventions

### Plugin file structure

Each file in `lua/plugins/` returns a lazy.nvim spec. Plugin-specific keymaps go inside the spec's `keys` or `config` fields, not in `lua/config/keymaps.lua`. Plugins are lazy-loaded via `keys`, `cmd`, `ft`, or `event` triggers.

Note the split convention for `keys`: when a keymap is defined inside `config`, the spec often *also* lists the bare lhs in `keys` (with only a `desc`) purely as a lazy-load trigger. `nvim-dap.lua` and `toggleterm.lua` both do this. Adding a keymap in `config` without a matching `keys` entry means it won't exist until the plugin loads for some other reason.

### The working-directory autocmd

`lua/config/options.lua:16` registers a `BufEnter` autocmd that runs `lcd` into the current file's directory for any path under `/home/`. This overlaps with `project.nvim` (`lua/plugins/project-nvim.lua`), which has `manual_mode = false` and `silent_chdir = true` and independently chdirs to a detected project root.

`nvim-jdtls.lua` deliberately does **not** use `getcwd()` for the jdtls workspace: it derives it from the project root, because cwd depends on where nvim was launched and on these chdir mechanisms, and different projects used to collide in one workspace. Don't switch it back to cwd. Root detection is **prioritized** (`vim.fs.root` with nested lists): build root first (`settings.gradle[.kts]`/`gradlew`/`mvnw`), then `build.gradle[.kts]`/`pom.xml`, then `.git` — in a multi-module Gradle build the nearest `build.gradle` is just a submodule, which can't be imported alone (it used `rootProject.ext` / `project(':sibling')`). The workspace name is `<root basename>-<first 8 hex of sha256(root path)>` so two projects with the same folder name don't share a workspace.

### Indentation

4-space indentation everywhere (`expandtab`, `tabstop=4`, `shiftwidth=4`). Uses `autoindent`, not `smartindent` — `smartindent` conflicts with `cindent` for C switch-case. `cinoptions = "g0,:0"`: `g0` places C++ access specifiers at class level, `:0` aligns `case` labels with their `switch`. `cindent` is enabled per-buffer for `c`/`cpp` via a `FileType` autocmd.

The Lua source in this repo is **tab**-indented (stylua's default), which does not match the `expandtab` setting the config imposes on edited files. Match the surrounding file.

### Folding

`_G.safe_foldexpr()` (`lua/config/options.lua:38`) wraps `vim.treesitter.foldexpr()` in a `pcall` and returns `"0"` on failure. A `FileType` autocmd sets `foldmethod=expr` / `foldexpr` only for buffers where `vim.treesitter.get_parser` succeeds. `foldlevelstart = 99` means files open unfolded. `<Tab>` toggles a fold.

### LSP setup

LSP is managed by mason + **mason-lspconfig v2** (`lua/plugins/nvim-lspconfig.lua`) on Neovim 0.12. v2 **removed `handlers` and `automatic_installation`** — passing them is silently ignored. Instead it calls `vim.lsp.enable()` for every Mason-installed server (`automatic_enable`), so per-server settings go through `vim.lsp.config("<name>", {...})` *before* `mason-lspconfig.setup`, and shared capabilities via `vim.lsp.config("*", ...)`. Note that lspconfig's own configs may define `root_dir` as a function, which overrides `root_markers` — override `root_dir` itself in that case (see `r_language_server`).

There is no `on_attach`; a global `LspAttach` autocmd (augroup `user_lsp_attach`) **disables** LSP formatting (`documentFormattingProvider = false`) for every client, jdtls and rust-analyzer included — formatting is conform's job. Inlay hints are enabled when the server supports them.

`automatic_enable.exclude`: `jdtls` (nvim-jdtls), `rust_analyzer` (rustaceanvim), `stylua` (conform runs it as a formatter), `neocmake` (would duplicate `cmake`). Any other server installed through `:Mason` is auto-enabled with defaults.

`ensure_installed`: `lua_ls`, `basedpyright`, `rust_analyzer`, `clangd`, `zls`, `cmake`, `r_language_server`, `kotlin_language_server`, `lemminx`. A server not in this list won't be installed on demand.

Per-server settings worth knowing:

- **clangd** — `--completion-style=detailed`, `--header-insertion=iwyu`, `--clang-tidy`
- **rust-analyzer** — run by **rustaceanvim** (`lua/plugins/rustaceanvim.lua`, `lazy = false`), not lspconfig; settings live in `vim.g.rustaceanvim.server.default_settings`: `fullFunctionSignatures`, postfix completions, clippy as the check command. Never re-enable `rust_analyzer` through mason-lspconfig — you get two rust-analyzer instances per buffer.
- **lua_ls** — `callSnippet = "Replace"`, `displayContext = 1`, `vim` declared as a global
- **basedpyright** — `typeCheckingMode = "standard"`, `autoImportCompletions`
- **zls** — `enable_argument_placeholders`, `completion_parse_comments`
- **kotlin_language_server** — pinned to Java 21 via `cmd_env` (`/usr/lib/jvm/java-21-openjdk`)
- **r_language_server** — filetypes restricted to `r`/`rmd`

**Java is a special case.** `jdtls` is excluded from `automatic_enable` and configured separately in `lua/plugins/nvim-jdtls.lua` via `mfussenegger/nvim-jdtls`. Because lazy runs `config` only once (first Java buffer), the spec registers a `FileType java` autocmd that calls `start_or_attach` per buffer — without it, only the first Java file gets LSP.

Settings are passed **both** as `config.settings` and `init_options.settings`: nvim-jdtls only sends `settings` via `didChangeConfiguration`, which arrives after jdtls has already done the initial project import, so import-related settings must be in `init_options`.

**Android projects** (AGP, `com.android.*`): Buildship doesn't understand AGP and imports modules with no source folders — every file reports *"X.java is not on the classpath of project Y, only syntax errors are reported"*. jdtls ships an `init.gradle` for this (`java.jdt.ls.androidSupport.enabled`, a **boolean** in jdtls — vscode-java's `"on"` is converted client-side), but it breaks on AGP 8 + Gradle 8.x. So this config keeps the built-in support **off** and passes a patched copy, `jdtls/android-init.gradle`, via `java.import.gradle.arguments = { "--init-script", ... }`. Patches (all marked `PATCH` in the file): sync tasks use `sourceGenTask` instead of `compileTask` (a compile error anywhere used to fail the whole import); `addPlusConfiguration` is disabled (it retargets project deps to `"default"` and calls `setCanBeResolved` on role-locked configurations); `AddCompileClasspathAction` resolves `debug[UnitTest]CompileClasspath` with `artifactType=android-classes-jar` and turns project deps into Eclipse project references (without `artifactType`, the eclipse plugin's lenient resolution silently drops AGP project deps due to variant ambiguity); the JDK container is **kept** (upstream removes it, relying on `android.jar`) — without it, at compliance ≥ 9 JDT's `ASTParser` throws `Missing system library` and jdtls returns **no code actions at all** in Android modules (diagnostics and codelens don't hit that path, so it looks half-working; the error shows in the jdtls workspace `.metadata/.log`). The script no-ops for non-Android projects. When upgrading jdtls, diff against the new `gradle/android/init.gradle` inside `org.eclipse.jdt.ls.core_*.jar`.

Dead ends already tried for Android, don't repeat them: disabling Gradle import to get an "invisible project" (jdtls refuses via `isPartOfMatureProject` when a `build.gradle`/`settings.gradle`/`pom.xml` sits above `src/`), and `java.import.exclusions` to stop the Eclipse importer (it ignores them).

Stale Buildship metadata in a project dir (`.project`, `.classpath`, `.settings/org.eclipse.buildship.core.prefs` with `override.workspace.settings=true`) **overrides workspace settings per module**, including the Gradle arguments — so the init script silently doesn't run for that module. If a module still says "not on the classpath", check its `.settings/` and remove the stale files plus the jdtls workspace.

`nvim-jdtls.lua` additionally:

- Requires the mason packages **`java-debug-adapter`** and **`java-test`**. If either is absent it only emits a `vim.notify` error and continues with an incomplete `bundles` list — debugging and test codelens silently degrade. Install them with `:MasonInstall java-debug-adapter java-test`.
- Configures Java runtimes for `JavaSE-17` and `JavaSE-21` from `/usr/lib/jvm/`.
- **Rebinds keymaps buffer-locally in Java buffers**, which shadows the global ones. `<leader>tr` becomes jdtls's run-nearest-test (not neotest's). `<leader>ln` becomes `vim.lsp.buf.rename` (not Lspsaga's). Debug hover is `<leader>di` here, versus `<leader>dh` everywhere else — a known inconsistency. It also adds `<leader>tm` (test nearest method) and `<leader>tc` (test class).
- Adds a `<leader>j` (Java) group of code-generation keys: `jg` getters+setters, `jG` getters, `jS` setters, `jc` constructor, `js` toString, `je` equals/hashCode, `jo` organize imports. They call `vim.lsp.buf.code_action` filtered by kind (`source.generate.*`) with `apply = true`; the three accessor actions share one kind, so they're also filtered by title. nvim-jdtls doesn't implement jdtls's accessor prompt, so accessors are generated for every field lacking them, inserted at the cursor position.

### Completion

`blink.cmp` (`lua/plugins/blink_cmp.lua`) v1.x with the `luasnip` snippet preset. Keymap preset: `enter`. Sources: lsp, path, snippets, buffer.

`<Tab>`/`<S-Tab>` navigate the menu, `<C-l>`/`<C-h>` jump snippet placeholders, `<C-s>` toggles signature, `<C-k>` toggles documentation, `<C-u>`/`<C-d>` scroll docs. Cmdline completion uses the `super-tab` preset instead.

### Custom snippets (LuaSnip)

`lua/plugins/luasnip.lua` — LuaSnip v2 with `history = true`, plus `delete_check_events`/`region_check_events` to clean up stale snippet sessions. Defines a `pack` snippet for Java and Kotlin that derives the `package` declaration by matching `src/.-/java/` or `src/.-/kotlin/` against the buffer path.

### Formatting

`conform.nvim` (`lua/plugins/conform.lua`). **There is no `format_on_save`** — the `event = { "BufWritePre" }` in the spec only lazy-loads the plugin; it does not install a save hook. Formatting happens on demand via `<leader>of`. Since the `LspAttach` autocmd also strips LSP formatting capabilities, the `default_format_opts.lsp_format = "fallback"` setting is effectively inert.

| Filetype | Formatter |
|---|---|
| Lua | stylua |
| Python | isort, black |
| Rust | rustfmt |
| C/C++/Java | clang-format (`IndentWidth: 4`, `UseTab: Never`, LLVM base) |
| Markdown/JSON/YAML/HTML/CSS | prettier (`--tab-width 4`) |

### Treesitter

`lua/plugins/treesitter.lua` tracks the **`main` branch** of nvim-treesitter and nvim-treesitter-textobjects, which uses the new API: parsers install via `require("nvim-treesitter").install({...})` (not the legacy `nvim-treesitter.configs` `setup{}`/`ensure_installed`), highlighting starts per-buffer from a `FileType` autocmd calling `vim.treesitter.start`, and textobject move/select calls take an explicit `"textobjects"` query-group argument.

The `main` branch dropped `nvim-treesitter.parsers.ft_to_lang` and friends. This config used to carry a monkey-patching shim that put them back, because Telescope pinned to `0.1.x` still called them. That is resolved: Telescope now tracks `master` (see below) and uses `vim.treesitter.language.get_lang` directly, so **the shim was removed and must not be reintroduced**. No installed plugin calls the legacy parsers API anymore — verify with `grep -rl 'ft_to_lang' ~/.local/share/nvim/lazy/ --exclude-dir=nvim-treesitter` before adding one back.

### Telescope must stay on `master`

Telescope's `0.1.x` branch is frozen at May 2024 and predates the nvim-treesitter `main` rewrite; on it, `previewers/utils.lua` calls the removed `ts_parsers.ft_to_lang` and the previewer/`:Telescope treesitter` picker throw `attempt to call field 'ft_to_lang' (a nil value)`. The fix landed on `master` only ([PR #3566](https://github.com/nvim-telescope/telescope.nvim/pull/3566), Nov 2025).

The `0.1.x` pin was not in `telescope.lua` — it was copy-pasted from venv-selector's README into `venv-selector.lua`'s `dependencies` block, and lazy.nvim merges that pin into the shared Telescope spec. **Do not re-add `branch = "0.1.x"` to any Telescope dependency entry.**

### Testing (neotest)

`lua/plugins/neotest.lua`, with adapters for Python (pytest), Go, Rust (rustaceanvim), Zig, Java (neotest-java), C++ (neotest-gtest), and CMake/CTest (neotest-ctest). Results are routed through overseer via the `overseer` consumer.

The Java adapter wraps neotest-java's `is_test_file` in a `pcall` and falls back to matching `/test/` path segments and `*Test.java` filenames when the built-in detection throws. The gtest adapter overrides `is_test_file` to accept any `.cpp`/`.cc`/`.cxx` file.

Remember that in Java buffers jdtls's buffer-local `<leader>tr` wins over neotest's.

### Debugging (nvim-dap)

`lua/plugins/nvim-dap.lua` plus `lua/plugins/nvim-dap-ui.lua` (which owns `<leader>dt` and `<leader>dh`). During an active session the arrow keys are remapped — Up=continue, Down=step over, Right=step into, Left=step out — and deleted again on `event_terminated`/`event_exited`/`disconnect`. `<leader>dx` removes them explicitly before terminating, since a terminate that doesn't fire those events would otherwise leave the arrows hijacked.

DAP adapters via mason-nvim-dap (`lua/plugins/mason-nvim-dap.lua`, the only place it's set up): `codelldb`, `python`, `delve`, `javadbg`, `javatest`. `ensure_installed` takes **nvim-dap adapter names**, not Mason package names (`python` → debugpy, `javadbg` → java-debug-adapter, `javatest` → java-test). `<leader>dw` attaches to an Android app running under Waydroid: it shells out to `waydroid status` for the IP (falling back to `192.168.240.112`), `adb connect`s, resolves the PID with `adb shell pidof`, forwards a random port to the JDWP transport, and attaches a `java` DAP session. The same function is duplicated verbatim in `nvim-jdtls.lua`.

### LSP UI (lspsaga)

`lua/plugins/lspsaga.lua` — loads on `LspAttach`. `<leader>ld` (goto definition), `<leader>lr` (finder), `<leader>ln` (rename), `<leader>la` (code action), `<leader>li` (hover doc), `[d`/`]d` (diagnostic jump). Lightbulb is disabled; winbar symbols are on.

### Multicursor

`lua/plugins/multicursor.lua` — `jake-stewart/multicursor.nvim`. Keymaps under `<leader>m`. Escape clears cursors or disables highlight search. Deliberately does **not** use `addKeymapLayer` — it blocks the which-key popup.

### Refactoring

`lua/plugins/refactoring.lua` — `ThePrimeagen/refactoring.nvim` (rewritten upstream; requires Neovim 0.12.5 and, on 0.12, the `lewis6991/async.nvim` dependency — without it `config` fails with `module 'async' not found`). The old `require("refactoring").refactor("Extract Function")` API and the Extract Block refactors are gone; it now exposes `extract_func`, `extract_func_to_file`, `extract_var`, `inline_func`, `inline_var`, `select_refactor`. Each returns an operator (`g@`), so keys set `expr = true` and work on a visual selection or a motion in normal mode (`<leader>reap`); `<leader>ree` / `<leader>rvv` append `_` for the current line. `<leader>rs` is `select_refactor` (not `expr`).

### Other notable plugins

- **overseer** (`<leader>x`) — builtin and vscode task templates.
- **cmake-tools** (`<leader>c`) — loaded for cmake/cpp/c filetypes.
- **mini.nvim** — `mini.move` on `<A-hjkl>`, `mini.surround` with vim-surround-style `ys`/`ds`/`cs` mappings.
- **quarto + molten + otter** — literate notebooks for qmd/markdown/python/r; molten's image provider is `none`. molten is a remote (Python) plugin: its spec has `build = ":UpdateRemotePlugins"` and sets its globals in `init`.

## Keymaps

Groups registered with which-key:

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

Not covered by a group prefix: `<C-n>` (neo-tree), `<Tab>` (toggle fold), `<leader>bb` (snacks buffer picker), `<leader>a`/`<leader>A` (swap parameter next/previous), `<leader>fR` (Telescope LSP references), `<leader>uh` (toggle inlay hints), `<leader>ut` (toggle terminal), `<leader>un` (notification history), `<C-.>`/`<C-,>` (resize window).

## UI & Appearance

- **Colorscheme**: tokyonight-night
- **Statusline**: lualine, global statusline (`laststatus = 3`)
- **File explorer**: neo-tree (`<C-n>`)
- **Notifications**: snacks notifier owns `vim.notify` (noice has `notify.enabled = false` and no nvim-notify); noice handles cmdline/messages
- **Indent guides**: indent-blankline (`snacks.indent` is disabled to avoid duplicate guides)
- **Dashboard/Picker**: snacks.nvim
- **Diagnostics**: Nerd Font icons (󰅚 error, 󰀪 warn, 󰌶 hint, 󰋽 info), inline virtual text with `●` prefix, rounded float borders
- **Git signs**: gitsigns.nvim — `<leader>gp` (preview), `<leader>gb` (blame), `<leader>gs` (stage), `<leader>gr` (reset)

## Known Issues

- `lua/plugins/gitsings.lua` — filename typo (should be `gitsigns.lua`), but functional since lazy.nvim imports by directory.
- Conform is documented and keymapped as a formatter but never runs on save (see [Formatting](#formatting)). If format-on-save is wanted, add `format_on_save` to `opts`.
- The `<leader>di` vs `<leader>dh` debug-hover split between Java and everything else is unintentional.
- `debug_waydroid` is copy-pasted between `nvim-dap.lua` and `nvim-jdtls.lua`; fixes must be applied to both.
