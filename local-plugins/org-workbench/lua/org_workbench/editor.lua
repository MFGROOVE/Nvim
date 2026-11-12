local parser = require("org_workbench.parser")
local M = {}
local namespace = vim.api.nvim_create_namespace("org_workbench")

function M.document(buf)
	return parser.parse(vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false), M.config.todo_keywords)
end

local function current()
	local doc = M.document()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	assert(not parser.in_block(doc, row), "Esta ação não se aplica dentro de um bloco literal")
	local heading = parser.heading_at(doc, row)
	assert(heading, "Posicione o cursor em um título Org")
	return doc, heading
end

function M.todo()
	local doc, h = current()
	local next_state = doc.states[1]
	for i, state in ipairs(doc.states) do
		if state == h.todo then
			next_state = doc.states[i + 1] -- After the final state, remove the keyword.
			break
		end
	end
	local text = doc.lines[h.line]:sub(h.level + 2)
	if h.todo then
		text = text:sub(#h.todo + 1):gsub("^%s+", "")
	end
	vim.api.nvim_buf_set_lines(0, h.line - 1, h.line, false, {
		string.rep("*", h.level) .. " " .. (next_state and (next_state .. " ") or "") .. text,
	})
end

function M.shift(amount)
	local doc, h = current()
	assert(h.level + amount >= 1, "Um título precisa de pelo menos uma estrela")
	local lines = vim.list_slice(doc.lines, h.line, h.end_line)
	-- Only parsed headings change; stars in source blocks stay literal.
	for _, child in ipairs(doc.headings) do
		if child.line >= h.line and child.line <= h.end_line then
			lines[child.line - h.line + 1] = string.rep("*", child.level + amount)
				.. doc.lines[child.line]:sub(child.level + 1)
		end
	end
	vim.api.nvim_buf_set_lines(0, h.line - 1, h.end_line, false, lines)
end

function M.heading()
	local doc = M.document()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	assert(not parser.in_block(doc, row), "Não insira títulos dentro de um bloco literal")
	local h = parser.heading_at(doc, row)
	local at = h and h.end_line or row
	local text = string.rep("*", h and h.level or 1) .. " "
	vim.api.nvim_buf_set_lines(0, at, at, false, { text })
	vim.api.nvim_win_set_cursor(0, { at + 1, #text })
	vim.cmd("startinsert!")
end

function M.checkbox()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	assert(not parser.in_block(M.document(), row), "Blocos literais não contêm checkboxes editáveis")
	local line = vim.api.nvim_get_current_line()
	local prefix, state, suffix = line:match("^(%s*[-+*]%s+)%[([ Xx-])%](.*)$")
	if not prefix then
		prefix, state, suffix = line:match("^(%s*%d+[.)]%s+)%[([ Xx-])%](.*)$")
	end
	assert(prefix, "Posicione o cursor em um item com checkbox")
	vim.api.nvim_set_current_line(prefix .. "[" .. (state == " " and "X" or " ") .. "]" .. suffix)
end

function M.plan(kind, value)
	assert(kind == "SCHEDULED" or kind == "DEADLINE", "Tipo de data inválido")
	assert(parser.date(value), "Data inválida; use AAAA-MM-DD")
	local doc, h = current()
	local stamp = kind .. ": <" .. value .. ">"
	local row = h.line + 1
	local line = doc.lines[row] or ""
	if line:match("^%s*SCHEDULED:") or line:match("^%s*DEADLINE:") or line:match("^%s*CLOSED:") then
		if line:find(kind .. ":", 1, true) then
			line = line:gsub(kind .. ":%s*<[^>]*>", stamp, 1)
		else
			line = line .. " " .. stamp
		end
		vim.api.nvim_buf_set_lines(0, row - 1, row, false, { line })
	else
		vim.api.nvim_buf_set_lines(0, h.line, h.line, false, { stamp })
	end
end

function M.clock_in()
	assert(not M.clock, "Já existe um relógio ativo nesta sessão")
	local doc, h = current()
	local buf = vim.api.nvim_get_current_buf()
	local stamp = os.date("[%Y-%m-%d %a %H:%M]")
	local row = h.line
	local planning = doc.lines[row + 1] or ""
	if planning:match("^%s*SCHEDULED:") or planning:match("^%s*DEADLINE:") or planning:match("^%s*CLOSED:") then
		row = row + 1
	end
	vim.api.nvim_buf_set_lines(buf, row, row, false, { "CLOCK: " .. stamp })
	M.clock = {
		buf = buf,
		start = os.time(),
		text = "CLOCK: " .. stamp,
		mark = vim.api.nvim_buf_set_extmark(buf, namespace, row, 0, {}),
	}
end

function M.clock_out()
	local clock = M.clock
	assert(clock and vim.api.nvim_buf_is_loaded(clock.buf), "Nenhum relógio ativo nesta sessão")
	local mark = vim.api.nvim_buf_get_extmark_by_id(clock.buf, namespace, clock.mark, {})
	assert(#mark > 0, "A linha do relógio foi removida")
	local line = vim.api.nvim_buf_get_lines(clock.buf, mark[1], mark[1] + 1, false)[1]
	assert(line == clock.text, "A linha do relógio mudou; encerre-a manualmente")
	local minutes = math.max(0, math.floor((os.time() - clock.start) / 60))
	local text = line
		.. "--"
		.. os.date("[%Y-%m-%d %a %H:%M]")
		.. string.format(" => %d:%02d", math.floor(minutes / 60), minutes % 60)
	vim.api.nvim_buf_set_lines(clock.buf, mark[1], mark[1] + 1, false, { text })
	vim.api.nvim_buf_del_extmark(clock.buf, namespace, clock.mark)
	M.clock = nil
end

function M.refile(path, archive)
	local doc, h = current()
	local source = vim.api.nvim_get_current_buf()
	local source_path = vim.api.nvim_buf_get_name(source)
	assert(source_path ~= "", "Salve o arquivo antes de mover uma árvore")
	path = archive and (source_path .. "_archive") or path
	assert(path and path ~= "", "Informe o arquivo de destino")
	path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
	assert(path ~= source_path, "Escolha um arquivo diferente do atual")
	assert(not M.clock or M.clock.buf ~= source, "Encerre o relógio antes de mover a árvore")
	local target = vim.fn.bufadd(path)
	vim.fn.bufload(target)
	assert(vim.bo[target].modifiable and not vim.bo[target].readonly, "Destino não pode ser editado")
	local target_lines = vim.api.nvim_buf_get_lines(target, 0, -1, false)
	local content = vim.list_slice(doc.lines, h.line, h.end_line)
	if #target_lines == 1 and target_lines[1] == "" then
		vim.api.nvim_buf_set_lines(target, 0, -1, false, content)
	else
		vim.api.nvim_buf_set_lines(target, -1, -1, false, content)
	end
	vim.bo[target].buflisted = true
	vim.api.nvim_buf_set_lines(source, h.line - 1, h.end_line, false, {})
	vim.notify("Árvore movida nos buffers. Use :wall para salvar origem e destino.")
end

function M.edit_source()
	local source = vim.api.nvim_get_current_buf()
	local block = parser.in_block(M.document(), vim.api.nvim_win_get_cursor(0)[1])
	assert(block and block.kind == "src" and block.closed, "Posicione o cursor em um bloco src completo")
	local original = vim.api.nvim_buf_get_lines(source, block.start_line - 1, block.end_line, false)
	local first = vim.api.nvim_buf_set_extmark(source, namespace, block.start_line - 1, 0, {})
	local last = vim.api.nvim_buf_set_extmark(source, namespace, block.end_line - 1, 0, {})
	vim.cmd("botright new")
	local edit = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_set_name(edit, "org-workbench://source/" .. edit)
	vim.bo[edit].buftype, vim.bo[edit].bufhidden, vim.bo[edit].swapfile = "acwrite", "wipe", false
	vim.api.nvim_buf_set_lines(edit, 0, -1, false, vim.list_slice(original, 2, #original - 1))
	local languages = { sh = "sh", shell = "sh", bash = "sh", emacs_lisp = "lisp", ["emacs-lisp"] = "lisp" }
	vim.bo[edit].filetype = languages[block.language] or block.language or "text"
	vim.bo[edit].modified = false
	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = edit,
		callback = function()
			if not vim.api.nvim_buf_is_loaded(source) then
				vim.notify("O buffer original foi fechado; copie suas alterações manualmente.", vim.log.levels.ERROR)
				return
			end
			local a = vim.api.nvim_buf_get_extmark_by_id(source, namespace, first, {})
			local b = vim.api.nvim_buf_get_extmark_by_id(source, namespace, last, {})
			if
				#a == 0
				or #b == 0
				or not vim.deep_equal(original, vim.api.nvim_buf_get_lines(source, a[1], b[1] + 1, false))
			then
				vim.notify("O bloco original mudou; copie suas alterações manualmente.", vim.log.levels.ERROR)
				return
			end
			local content = vim.api.nvim_buf_get_lines(edit, 0, -1, false)
			vim.api.nvim_buf_set_lines(source, a[1] + 1, b[1], false, content)
			original = { original[1] }
			vim.list_extend(original, content)
			original[#original + 1] = "#+end_src"
			-- Preserve the user's exact closing delimiter for future conflict checks.
			original[#original] = vim.api.nvim_buf_get_lines(source, a[1] + #content + 1, a[1] + #content + 2, false)[1]
			vim.bo[edit].modified = false
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = edit,
		once = true,
		callback = function()
			if vim.api.nvim_buf_is_valid(source) then
				vim.api.nvim_buf_del_extmark(source, namespace, first)
				vim.api.nvim_buf_del_extmark(source, namespace, last)
			end
		end,
	})
end

function M.table_align()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local first, last = vim.api.nvim_win_get_cursor(0)[1], vim.api.nvim_win_get_cursor(0)[1]
	assert(lines[first]:match("^%s*|"), "Posicione o cursor em uma tabela")
	while first > 1 and lines[first - 1]:match("^%s*|") do
		first = first - 1
	end
	while last < #lines and lines[last + 1]:match("^%s*|") do
		last = last + 1
	end
	local widths, rows = {}, {}
	for row = first, last do
		if lines[row]:match("^%s*|[-+|]+|%s*$") then
			rows[#rows + 1] = false
		else
			local text = lines[row]:gsub("^%s*|", ""):gsub("|%s*$", "")
			local cells = vim.split(text, "|", { plain = true })
			for col, cell in ipairs(cells) do
				cells[col] = vim.trim(cell)
				widths[col] = math.max(widths[col] or 0, vim.fn.strdisplaywidth(cells[col]))
			end
			rows[#rows + 1] = cells
		end
	end
	local output = {}
	for _, cells in ipairs(rows) do
		local parts = {}
		for col, width in ipairs(widths) do
			local text = cells and (cells[col] or "")
			parts[col] = text and (" " .. text .. string.rep(" ", width - vim.fn.strdisplaywidth(text) + 1))
				or string.rep("-", width + 2)
		end
		output[#output + 1] = "|" .. table.concat(parts, cells and "|" or "+") .. "|"
	end
	vim.api.nvim_buf_set_lines(0, first - 1, last, false, output)
end

return M
