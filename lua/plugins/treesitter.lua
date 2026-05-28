return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		lazy = false,
		dependencies = {
			{ "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
		},
		config = function()
			local parsers = require("nvim-treesitter.parsers")
			parsers.ft_to_lang = function(ft)
				return vim.treesitter.language.get_lang(ft) or ft
			end
			parsers.get_parser_configs = parsers.get_parser_configs or function() return {} end
			parsers.available_parsers = parsers.available_parsers or function() return {} end
			parsers.get_parser = parsers.get_parser or function(buf, lang)
				return vim.treesitter.get_parser(buf, lang)
			end

			-- Telescope's utils.lua captures a stale ts_parsers reference; also patch
			-- via package.loaded with a metatable so any future require gets ft_to_lang.
			local function reapply()
				local p = package.loaded["nvim-treesitter.parsers"]
				if type(p) == "table" and not p.ft_to_lang then
					p.ft_to_lang = parsers.ft_to_lang
					p.get_parser = parsers.get_parser
					p.get_parser_configs = parsers.get_parser_configs
					p.available_parsers = parsers.available_parsers
				end
			end
			reapply()
			vim.api.nvim_create_autocmd({ "User" }, {
				pattern = "LazyLoad",
				callback = reapply,
			})
			vim.api.nvim_create_autocmd("BufWinEnter", { callback = reapply })

			local fp = io.open("/tmp/nvim-shim-debug.log", "a")
			if fp then
				fp:write(os.date() .. " shim installed; ft_to_lang on parsers table = " .. tostring(parsers.ft_to_lang) .. "\n")
				fp:write("  package.loaded[parsers] same identity = " .. tostring(parsers == package.loaded["nvim-treesitter.parsers"]) .. "\n")
				fp:close()
			end

			require("nvim-treesitter").install({
				"c",
				"cpp",
				"rust",
				"zig",
				"python",
				"lua",
				"markdown",
				"markdown_inline",
				"vim",
				"vimdoc",
				"bash",
				"asm",
				"cmake",
				"r",
				"java",
				"kotlin",
				"comment",
				"regex",
				"query",
			})

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})

			require("nvim-treesitter-textobjects").setup({
				move = { set_jumps = true },
			})

			local move = require("nvim-treesitter-textobjects.move")
			local select = require("nvim-treesitter-textobjects.select")
			local swap = require("nvim-treesitter-textobjects.swap")

			local map = vim.keymap.set

			map({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.inner", "textobjects") end, { desc = "Next parameter" })
			map({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "Previous parameter" })
			map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next function" })
			map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Previous function" })
			map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "Next class" })
			map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "Previous class" })

			map({ "x", "o" }, "af", function() select.select_textobject("@function.outer", "textobjects") end, { desc = "Around function" })
			map({ "x", "o" }, "if", function() select.select_textobject("@function.inner", "textobjects") end, { desc = "Inner function" })
			map({ "x", "o" }, "ac", function() select.select_textobject("@class.outer", "textobjects") end, { desc = "Around class" })
			map({ "x", "o" }, "ic", function() select.select_textobject("@class.inner", "textobjects") end, { desc = "Inner class" })
			map({ "x", "o" }, "aa", function() select.select_textobject("@parameter.outer", "textobjects") end, { desc = "Around parameter" })
			map({ "x", "o" }, "ia", function() select.select_textobject("@parameter.inner", "textobjects") end, { desc = "Inner parameter" })

			map("n", "<leader>a", function() swap.swap_next("@parameter.inner") end, { desc = "Swap parameter next" })
			map("n", "<leader>A", function() swap.swap_previous("@parameter.inner") end, { desc = "Swap parameter previous" })
		end,
	},
}
