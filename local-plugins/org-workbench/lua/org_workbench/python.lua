local M = { sessions = {} }
local worker = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h") .. "/runtime/python_worker.py"
local serial = 0

local function command(runner, token, once)
	local result = {}
	for _, arg in ipairs(runner) do
		if arg ~= "{file}" and arg ~= "-" then
			result[#result + 1] = arg
		end
	end
	vim.list_extend(result, { "-u", worker, token })
	if once then
		result[#result + 1] = "--once"
	end
	return result
end

local function decode(text, token)
	for line in text:gmatch("[^\n]+") do
		if vim.startswith(line, token) then
			local ok, data = pcall(vim.json.decode, line:sub(#token + 1))
			if ok then
				return data
			end
		end
	end
end

local function close_timer(item)
	if item.timer then
		item.timer:stop()
		item.timer:close()
		item.timer = nil
	end
end

local dispatch
local function terminate(session, code, reason)
	if session.closed then
		return
	end
	session.closed = true
	M.sessions[session.key] = nil
	if session.job then
		vim.fn.jobstop(session.job)
	end
	local pending = session.queue
	session.queue = {}
	if session.active then
		table.insert(pending, 1, session.active)
		session.active = nil
	end
	for _, item in ipairs(pending) do
		close_timer(item)
		vim.schedule(function()
			item.callback({ code = code, signal = 0, stdout = "", stderr = reason or "" })
		end)
	end
end

dispatch = function(session)
	if session.closed or session.active or #session.queue == 0 then
		return
	end
	local item = table.remove(session.queue, 1)
	session.active = item
	item.timer = vim.uv.new_timer()
	item.timer:start(
		item.timeout,
		0,
		vim.schedule_wrap(function()
			terminate(session, 124, "Sessão reiniciada após exceder o tempo limite")
		end)
	)
	vim.fn.chansend(session.job, vim.json.encode(item.request) .. "\n")
end

function M.run(request, runner, timeout, callback)
	serial = serial + 1
	request.id = serial
	local token = "ORG_WORKBENCH_" .. serial .. "_"
	if not request.session then
		return vim.system(
			command(runner, token, true),
			{ stdin = vim.json.encode(request) .. "\n", text = true, timeout = timeout },
			vim.schedule_wrap(function(result)
				local decoded = decode(result.stdout or "", token)
				callback(decoded or {
					code = result.code == 0 and 1 or result.code,
					signal = result.signal,
					stdout = "",
					stderr = result.stderr ~= "" and result.stderr
						or "O interpretador não retornou uma resposta válida",
				})
			end)
		)
	end
	local key = vim.json.encode(runner) .. ":" .. request.session
	local session = M.sessions[key]
	if not session then
		session = { key = key, name = request.session, queue = {}, partial = "", token = token }
		M.sessions[key] = session
		session.job = vim.fn.jobstart(command(runner, token), {
			on_stdout = function(_, data)
				local text = session.partial .. table.concat(data, "\n")
				local last = 1
				for line, after in text:gmatch("([^\n]*)\n()") do
					last = after
					local result = decode(line, session.token)
					local active = session.active
					if result and active and result.id == active.request.id then
						close_timer(active)
						session.active = nil
						vim.schedule(function()
							active.callback(result)
							dispatch(session)
						end)
					end
				end
				session.partial = text:sub(last)
			end,
			on_stderr = function(_, data)
				session.stderr = (session.stderr or "") .. table.concat(data, "\n")
			end,
			on_exit = function(_, code)
				if not session.closed then
					terminate(session, code == 0 and 1 or code, session.stderr or "A sessão Python foi encerrada")
				end
			end,
		})
		if session.job <= 0 then
			M.sessions[key] = nil
			error("Não foi possível iniciar a sessão Python")
		end
	end
	local item = { request = request, timeout = timeout, callback = callback }
	session.queue[#session.queue + 1] = item
	dispatch(session)
	return {
		kill = function()
			if session.active == item then
				terminate(session, 143, "Sessão encerrada; variáveis removidas")
			else
				for i, pending in ipairs(session.queue) do
					if pending == item then
						table.remove(session.queue, i)
						vim.schedule(function()
							callback({ code = 143, signal = 15, stdout = "", stderr = "Execução cancelada na fila" })
						end)
						break
					end
				end
			end
		end,
	}
end

function M.reset(name)
	local count, sessions = 0, {}
	for _, session in pairs(M.sessions) do
		if not name or name == "" or name == session.name then
			sessions[#sessions + 1] = session
		end
	end
	for _, session in ipairs(sessions) do
		terminate(session, 143, "Sessão reiniciada")
		count = count + 1
	end
	return count
end

local group = vim.api.nvim_create_augroup("org_workbench_python", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", {
	group = group,
	callback = function()
		M.reset()
	end,
})
return M
