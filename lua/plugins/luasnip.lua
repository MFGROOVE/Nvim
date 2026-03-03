return {
	"L3MON4D3/LuaSnip",
	version = "v2.*",
	build = "make install_jsregexp",
	config = function()
		local ls = require("luasnip")
		local s = ls.snippet
		local t = ls.text_node
		local f = ls.function_node

		ls.config.set_config({
			history = true,
			updateevents = "TextChanged,TextChangedI",
			delete_check_events = "TextChanged",
			region_check_events = "CursorMoved",
		})

		local function get_package_name()
			local path = vim.fn.expand("%:p")
			local pattern = "src/.-/java/"
			local _, end_idx = string.find(path, pattern)

			if not end_idx then
				pattern = "src/.-/kotlin/"
				_, end_idx = string.find(path, pattern)
			end

			if end_idx then
				local sub_path = string.sub(path, end_idx + 1)
				local package_path = vim.fn.fnamemodify(sub_path, ":h")
				return string.gsub(package_path, "/", ".")
			end

			return "package.not.found"
		end

		ls.add_snippets("java", {
			s("pack", {
				t("package "),
				f(get_package_name, {}),
				t(";"),
			}),
		})

		ls.add_snippets("kotlin", {
			s("pack", {
				t("package "),
				f(get_package_name, {}),
			}),
		})
	end,
}
