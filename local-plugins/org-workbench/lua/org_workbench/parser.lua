local M = {}

function M.keywords(sequence)
	local states, done, finished = {}, {}, false
	local has_separator = sequence:find("|", 1, true) ~= nil
	for word in sequence:gmatch("%S+") do
		if word == "|" then
			finished = true
		else
			local state = word:match("^([^%(]+)")
			states[#states + 1] = state
			done[state] = finished
		end
	end
	if not has_separator and #states > 0 then
		done[states[#states]] = true
	end
	return states, done
end

function M.date(value)
	local y, m, d = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	if not y then
		return nil
	end
	local timestamp = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
	if timestamp and os.date("%Y-%m-%d", timestamp) == value then
		return timestamp
	end
end

function M.parse(lines, sequence)
	local document = { headings = {}, blocks = {}, lines = lines, named = {}, file_headers = {} }
	local active_block
	-- Keywords inside source/example blocks are literal text.
	local literal
	for _, line in ipairs(lines) do
		local lower = line:lower()
		if not literal then
			sequence = line:match("^#%+[Tt][Oo][Dd][Oo]:%s*(.+)$") or sequence
			literal = lower:match("^%s*#%+begin_(%S+)")
		elseif lower:match("^%s*#%+end_(%S+)%s*$") == literal then
			literal = nil
		end
	end
	document.states, document.done = M.keywords(sequence or "TODO NEXT WAITING | DONE CANCELLED")
	local state_set = {}
	for _, state in ipairs(document.states) do
		state_set[state] = true
	end
	local stack, current, affiliated, drawer = {}, nil, {}, false
	for row, line in ipairs(lines) do
		local lower = line:lower()
		if active_block then
			if lower:match("^%s*#%+end_(%S+)%s*$") == active_block.kind then
				active_block.end_line = row
				active_block.closed = true
				active_block = nil
			end
		else
			local property, property_value = lower:match("^%s*#%+property:%s+(header%-args[^%s]*)%s+(.*)$")
			if property then
				document.file_headers[#document.file_headers + 1] =
					{ key = property, value = line:match("^%s*#%+%S+%s+%S+%s+(.*)$") }
			end
			local affiliated_key, affiliated_value = line:match("^%s*#%+([%a]+):%s*(.*)$")
			if affiliated_key then
				affiliated_key = affiliated_key:lower()
				if affiliated_key == "name" then
					affiliated.name = affiliated_value
				elseif affiliated_key == "header" or affiliated_key == "headers" then
					affiliated.headers = affiliated.headers or {}
					affiliated.headers[#affiliated.headers + 1] = affiliated_value
				end
			end
			local kind = lower:match("^%s*#%+begin_(%S+)")
			if kind then
				active_block = {
					kind = kind,
					start_line = row,
					end_line = #lines,
					closed = false,
					name = affiliated.name,
					headers = affiliated.headers,
					heading = current,
				}
				if kind == "src" then
					active_block.language, active_block.args = line:match("^%s*#%+%S+%s+(%S+)%s*(.*)$")
				end
				document.blocks[#document.blocks + 1] = active_block
				if active_block.name then
					document.named[active_block.name] = active_block
				end
				affiliated = {}
			else
				local stars, text = line:match("^(%*+)%s+(.*)$")
				if stars then
					drawer = false
					local h = { line = row, level = #stars, title = text, end_line = #lines, properties = {} }
					local first, rest = text:match("^(%S+)%s*(.*)$")
					if state_set[first] then
						h.todo, h.title = first, rest
					end
					h.priority = h.title:match("^%[#([A-Z])%]%s*")
					if h.priority then
						h.title = h.title:gsub("^%[#[A-Z]%]%s*", "")
					end
					h.tags = h.title:match("%s+(:[%w_@#%%:]+:)%s*$")
					if h.tags then
						h.title = h.title:gsub("%s+:[%w_@#%%:]+:%s*$", "")
					end
					while #stack > 0 and stack[#stack].level >= h.level do
						stack[#stack].end_line = row - 1
						table.remove(stack)
					end
					h.parent = stack[#stack]
					stack[#stack + 1] = h
					document.headings[#document.headings + 1], current = h, h
				elseif current then
					if lower:match("^%s*:properties:%s*$") then
						drawer = true
					elseif lower:match("^%s*:end:%s*$") then
						drawer = false
					elseif drawer then
						local key, value = line:match("^%s*:([%w_:+-]+):%s*(.-)%s*$")
						if key then
							current.properties[key:lower()] = value
						end
					end
					-- Planning keywords only have meaning on planning lines.
					if line:match("^%s*SCHEDULED:") or line:match("^%s*DEADLINE:") or line:match("^%s*CLOSED:") then
						current.scheduled = line:match("SCHEDULED:%s*<(%d%d%d%d%-%d%d%-%d%d)[^>]*>")
							or current.scheduled
						current.deadline = line:match("DEADLINE:%s*<(%d%d%d%d%-%d%d%-%d%d)[^>]*>") or current.deadline
					end
				end
				if affiliated.name and line:match("^%s*|") then
					document.named[affiliated.name] = { kind = "table", start_line = row, name = affiliated.name }
				end
				if not affiliated_key then
					affiliated = {}
				end
			end
		end
	end
	return document
end

function M.heading_at(document, row)
	for i = #document.headings, 1, -1 do
		local heading = document.headings[i]
		if heading.line <= row and row <= heading.end_line then
			return heading
		end
	end
end

function M.in_block(document, row)
	for _, block in ipairs(document.blocks) do
		if row >= block.start_line and row <= block.end_line then
			return block
		end
	end
end

return M
