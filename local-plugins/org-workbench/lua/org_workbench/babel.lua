local parser = require("org_workbench.parser")
local editor = require("org_workbench.editor")
local context = require("org_workbench.context")
local headers = require("org_workbench.headers")
local results = require("org_workbench.results")
local languages = require("org_workbench.languages")
local python = require("org_workbench.python")
local M = { running = {} }
local ns = vim.api.nvim_create_namespace("org_workbench_babel")
local serial = 0

local function finish(job, result)
	if job.script then
		vim.fn.delete(job.script)
	end
	job.result = result
	local ok, err = pcall(function()
		assert(vim.api.nvim_buf_is_loaded(job.buf), "O buffer original foi fechado")
		assert(vim.bo[job.buf].modifiable, "O buffer original não pode ser editado")
		local mark = vim.api.nvim_buf_get_extmark_by_id(job.buf, ns, job.mark, {})
		assert(#mark > 0, "O bloco original foi removido")
		local first, last = mark[1], mark[1] + #job.original
		assert(
			vim.deep_equal(job.original, vim.api.nvim_buf_get_lines(job.buf, first, last, false)),
			"O bloco mudou durante a execução; resultados não inseridos"
		)
		local lines = vim.api.nvim_buf_get_lines(job.buf, 0, -1, false)
		local a, b = results.span(lines, last)
		local previous = vim.list_slice(lines, a + 1, b)
		assert(
			vim.deep_equal(job.old_results, previous),
			"Os resultados mudaram durante a execução; saída não inserida"
		)
		if job.no_insert then
			return
		end
		local content = results.render(job, result)
		if not content then
			return
		end
		if job.options.append and #previous > 0 then
			content = vim.list_extend(vim.list_slice(previous, 2), content)
		elseif job.options.prepend and #previous > 0 then
			vim.list_extend(content, vim.list_slice(previous, 2))
		end
		table.insert(content, 1, job.indent .. "#+RESULTS:" .. (job.name and " " .. job.name or ""))
		vim.api.nvim_buf_set_lines(job.buf, a, b, false, content)
	end)
	if vim.api.nvim_buf_is_valid(job.buf) then
		vim.api.nvim_buf_del_extmark(job.buf, ns, job.mark)
	end
	if M.running[job.buf] then
		M.running[job.buf][job.mark] = nil
		if not next(M.running[job.buf]) then
			M.running[job.buf] = nil
		end
	end
	job.done, job.error = true, not ok and tostring(err) or nil
	if not ok then
		vim.notify(tostring(err), vim.log.levels.WARN)
	elseif result.code ~= 0 and not job.cancelled then
		vim.notify("Org: execução falhou; veja #+RESULTS", vim.log.levels.ERROR)
	end
	if job.callback then
		job.callback(job)
	end
end

local function executable(args)
	local eval = headers.get(args, "eval", "yes")
	assert(eval ~= "no" and eval ~= "never", "Este bloco desabilita execução com :eval")
	assert(eval == "yes" or eval == "never-export" or eval == "no-export", "Valor :eval ainda não suportado: " .. eval)
end

local supported_results = {}
for word in
	("output value replace append prepend silent none verbatim scalar table vector list raw code drawer html latex org file link graphics"):gmatch(
		"%S+"
	)
do
	supported_results[word] = true
end

function M.execute_at(buf, block, callback, settings)
	settings = settings or {}
	local doc = editor.document(buf)
	assert(block and block.kind == "src" and block.closed, "Posicione o cursor dentro de um bloco #+begin_src completo")
	assert(vim.bo[buf].modifiable, "O buffer não pode ser editado")
	local stack = vim.deepcopy(settings.stack or {})
	assert(not stack[block.start_line], "Referência circular entre blocos de código")
	stack[block.start_line] = true
	for _, job in pairs(not settings.no_insert and M.running[buf] or {}) do
		local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, job.mark, {})
		assert(#mark == 0 or mark[1] ~= block.start_line - 1, "Este bloco já está em execução")
	end
	local args = context.arguments(doc, block, M.config)
	headers.merge(args, settings.overrides or {})
	executable(args)
	for _, key in ipairs({ "stdin", "post", "cache", "cmdline", "rownames", "hlines" }) do
		assert(not args[key] or headers.get(args, key) == "no", "Cabeçalho ainda não suportado: :" .. key)
	end
	for _, option in ipairs(args.results or {}) do
		assert(supported_results[option], "Opção :results ainda não suportada: " .. option)
	end
	local options = results.options(args)
	local mode = options.value and "value" or "output"
	local language = (block.language or ""):lower()
	local runner = M.config.runners[language]
	assert(type(runner) == "table" and #runner > 0, "Linguagem não configurada: " .. tostring(block.language))
	assert(vim.fn.executable(runner[1]) == 1, "Interpretador não encontrado: " .. runner[1])
	local session = args.session and headers.get(args, "session", "default")
	if session == "none" then
		session = nil
	end
	local is_python = language == "python" or language == "python3"
	assert(not session or is_python, "Sessões persistentes estão implementadas para Python")
	local filename = vim.api.nvim_buf_get_name(buf)
	local cwd = filename ~= "" and not filename:match("^%w[%w_-]*://") and vim.fn.fnamemodify(filename, ":h")
		or vim.fn.getcwd()
	if args.dir then
		assert(#args.dir == 1, 'Use :dir caminho ou :dir "caminho com espaços"')
		local dir = vim.fn.expand(headers.get(args, "dir"))
		cwd = vim.startswith(dir, "/") and dir or vim.fs.joinpath(cwd, dir)
	end
	assert(vim.fn.isdirectory(cwd) == 1, "Diretório de execução não existe: " .. cwd)
	local variables, dependencies, metadata = context.variables(doc, args, settings.resolved)
	local noweb = headers.get(args, "noweb", "no")
	assert(
		vim.tbl_contains({ "no", "yes", "eval", "tangle", "no-export", "strip-export", "strip-tangle" }, noweb),
		"Opção :noweb não suportada"
	)
	local expand = noweb == "yes" or noweb == "eval" or noweb == "no-export" or noweb == "strip-export"
	local code, noweb_dependencies
	if expand then
		code, noweb_dependencies = context.expand(doc, block, M.config)
	else
		code = context.body(doc, block)
	end
	vim.list_extend(dependencies, noweb_dependencies or {})
	if args.prologue then
		code = table.concat(vim.tbl_map(headers.unquote, args.prologue), " ") .. "\n" .. code
	end
	if args.epilogue then
		code = code .. "\n" .. table.concat(vim.tbl_map(headers.unquote, args.epilogue), " ")
	end
	if args["return"] then
		assert(is_python and not session and mode == "value", ":return requer Python value sem sessão")
		code = code .. "\nreturn " .. table.concat(args["return"], " ")
	end
	local file = headers.get(args, "file")
	if args["output-dir"] and file then
		file = vim.fs.joinpath(headers.get(args, "output-dir"), file)
	end
	if options.graphics then
		assert(is_python and file, "Gráficos automáticos requerem Python e :file")
	end
	local a, b = results.span(doc.lines, block.end_line)
	serial = serial + 1
	local token = "ORG_WORKBENCH_VALUE_" .. serial .. "_"
	local job = {
		buf = buf,
		mark = vim.api.nvim_buf_set_extmark(buf, ns, block.start_line - 1, 0, {}),
		original = vim.list_slice(doc.lines, block.start_line, block.end_line),
		old_results = vim.list_slice(doc.lines, a + 1, b),
		indent = doc.lines[block.start_line]:match("^(%s*)"),
		name = block.name,
		args = args,
		options = options,
		language = language,
		cwd = cwd,
		file = file,
		max_output_bytes = M.config.max_output_bytes,
		callback = callback,
		table_header = metadata.table_header,
		no_insert = settings.no_insert,
	}
	M.running[buf] = M.running[buf] or {}
	M.running[buf][job.mark] = job
	local function launch()
		local ok, process = pcall(function()
			if is_python then
				return python.run(
					{
						code = code,
						variables = variables,
						mode = mode,
						session = session,
						cwd = cwd,
						filename = filename ~= "" and filename or "<org>",
						max_output_bytes = M.config.max_output_bytes,
						table = options.table or options.vector,
						graphics = options.graphics,
						file = file and (vim.startswith(file, "/") and file or vim.fs.joinpath(cwd, file)) or nil,
					},
					runner,
					M.config.timeout_ms,
					function(result)
						finish(job, result)
					end
				)
			end
			local prepared = languages.prepare(language, code, variables, mode, token)
			local command, uses_file = {}, false
			for _, arg in ipairs(runner) do
				if arg == "{file}" then
					job.script = job.script or vim.fn.tempname()
					command[#command + 1], uses_file = job.script, true
				else
					command[#command + 1] = arg
				end
			end
			if uses_file then
				vim.fn.writefile(vim.split(prepared, "\n", { plain = true }), job.script)
			end
			return vim.system(
				command,
				{ stdin = not uses_file and prepared or nil, cwd = cwd, text = true, timeout = M.config.timeout_ms },
				vim.schedule_wrap(function(result)
					finish(job, languages.decode(result, token, mode))
				end)
			)
		end)
		if not ok then
			if job.script then
				vim.fn.delete(job.script)
			end
			M.running[buf][job.mark] = nil
			vim.api.nvim_buf_del_extmark(buf, ns, job.mark)
			finish(job, { code = 1, signal = 0, stdout = "", stderr = tostring(process) })
			return
		end
		job.process = process
	end
	if #dependencies == 0 then
		launch()
	else
		local child, resolved = nil, {}
		job.process = {
			kill = function()
				job.cancelled = true
				if child and child.process then
					child.process:kill(15)
				end
			end,
		}
		local function next_dependency()
			local dependency = table.remove(dependencies, 1)
			if not dependency then
				variables = context.variables(doc, args, resolved)
				if expand then
					local expanded = context.expand(doc, block, M.config, nil, resolved)
					local original_body = context.expand(doc, block, M.config)
					-- Replace the body while retaining any explicit prologue/epilogue.
					local start = code:find(original_body, 1, true)
					if start then
						code = code:sub(1, start - 1) .. expanded .. code:sub(start + #original_body)
					end
				end
				launch()
				return
			end
			local ok, value = pcall(M.execute_at, buf, dependency.target, function(completed)
				if job.cancelled or completed.error or completed.result.code ~= 0 then
					finish(job, {
						code = 1,
						signal = 0,
						stdout = "",
						stderr = completed.error or completed.result.stderr or "Dependência falhou",
					})
					return
				end
				if completed.options.value then
					resolved[dependency.key] = completed.result.value
				else
					resolved[dependency.key] = vim.trim(completed.result.stdout or "")
				end
				if resolved[dependency.key] == nil then
					resolved[dependency.key] = vim.NIL
				end
				next_dependency()
			end, { no_insert = true, stack = stack, overrides = context.call_arguments(dependency.arguments or "") })
			if ok then
				child = value
			else
				finish(job, { code = 1, signal = 0, stdout = "", stderr = tostring(value) })
			end
		end
		next_dependency()
	end
	return job
end

function M.execute(name)
	local buf, doc = vim.api.nvim_get_current_buf(), editor.document()
	local block
	if name and name ~= "" then
		block = assert(doc.named[name], "Bloco nomeado não encontrado: " .. name)
	else
		block = parser.in_block(doc, vim.api.nvim_win_get_cursor(0)[1])
	end
	return M.execute_at(buf, block)
end

function M.execute_all()
	local buf, queue = vim.api.nvim_get_current_buf(), {}
	for _, block in ipairs(editor.document().blocks) do
		if block.kind == "src" and block.closed then
			queue[#queue + 1] = vim.api.nvim_buf_set_extmark(buf, ns, block.start_line - 1, 0, {})
		end
	end
	local batch = { jobs = {}, done = false }
	local function advance()
		local mark = table.remove(queue, 1)
		if not mark then
			batch.done = true
			return
		end
		if not vim.api.nvim_buf_is_loaded(buf) then
			batch.done = true
			return
		end
		local position = vim.api.nvim_buf_get_extmark_by_id(buf, ns, mark, {})
		vim.api.nvim_buf_del_extmark(buf, ns, mark)
		local doc = editor.document(buf)
		local block = #position > 0 and parser.in_block(doc, position[1] + 1)
		if block then
			local eval = headers.get(context.arguments(doc, block, M.config), "eval", "yes")
			if eval == "no" or eval == "never" then
				advance()
				return
			end
		end
		local ok, job = pcall(M.execute_at, buf, block, function(completed)
			if completed.error or completed.result.code ~= 0 then
				batch.error = completed.error or "Um bloco falhou"
				batch.done = true
				for _, pending in ipairs(queue) do
					vim.api.nvim_buf_del_extmark(buf, ns, pending)
				end
			else
				advance()
			end
		end)
		if ok then
			batch.jobs[#batch.jobs + 1] = job
		else
			batch.error, batch.done = tostring(job), true
			for _, pending in ipairs(queue) do
				vim.api.nvim_buf_del_extmark(buf, ns, pending)
			end
			vim.notify(batch.error, vim.log.levels.ERROR)
		end
	end
	advance()
	return batch
end

function M.cancel()
	local buf = vim.api.nvim_get_current_buf()
	local block = parser.in_block(editor.document(buf), vim.api.nvim_win_get_cursor(0)[1])
	assert(block, "Posicione o cursor no bloco em execução")
	for _, job in pairs(M.running[buf] or {}) do
		local mark = vim.api.nvim_buf_get_extmark_by_id(buf, ns, job.mark, {})
		if #mark > 0 and mark[1] == block.start_line - 1 then
			job.cancelled = true
			job.process:kill(15)
			return
		end
	end
	error("Este bloco não está em execução")
end

function M.reset_session(name)
	vim.notify("Org: " .. python.reset(name) .. " sessão(ões) encerrada(s)")
end

function M.insert(language)
	if not language or language == "" then
		local buf, row = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1]
		vim.ui.input({ prompt = "Linguagem do bloco: ", default = "python" }, function(answer)
			if answer and vim.api.nvim_get_current_buf() == buf and vim.api.nvim_win_get_cursor(0)[1] == row then
				local ok, err = pcall(M.insert, answer)
				if not ok then
					vim.notify(tostring(err), vim.log.levels.ERROR)
				end
			end
		end)
		return
	end
	assert(language:match("^[%w_+.-]+$"), "Nome de linguagem inválido")
	local row = vim.api.nvim_win_get_cursor(0)[1]
	assert(not parser.in_block(editor.document(), row), "Saia do bloco atual antes de criar outro")
	vim.api.nvim_buf_set_lines(
		0,
		row,
		row,
		false,
		{ "#+begin_src " .. language .. " :results output", "", "#+end_src" }
	)
	vim.api.nvim_win_set_cursor(0, { row + 2, 0 })
end

local group = vim.api.nvim_create_augroup("org_workbench_babel", { clear = true })
vim.api.nvim_create_autocmd("BufWipeout", {
	group = group,
	callback = function(event)
		for _, job in pairs(M.running[event.buf] or {}) do
			if job.process then
				job.cancelled = true
				job.process:kill(15)
			end
		end
	end,
})
return M
