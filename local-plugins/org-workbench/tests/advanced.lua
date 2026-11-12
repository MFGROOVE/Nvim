return function(eq, wait, lines, text, tmp, root)
	local babel = require("org_workbench.babel")
	local python = require("org_workbench.python")
	vim.fn.writefile({ "answer = 42" }, tmp .. "/org_local.py")
	lines({ "#+begin_src python :results output", "import org_local; print(org_local.answer)", "#+end_src" })
	wait(babel.execute())
	eq(": 42", text()[5])
	lines({ "#+name: resposta", "#+begin_src python :results value :var x=21", "return x * 2", "#+end_src" })
	local named = wait(babel.execute("resposta"))
	eq(42, named.result.value)
	eq("#+RESULTS: resposta", text()[5])
	eq(": 42", text()[6])
	lines({ '#+begin_src python :results value :var msg="olá mundo" :var n=2', "return msg * n", "#+end_src" })
	wait(babel.execute())
	eq(": olá mundoolá mundo", text()[5])
	lines({ "#+begin_src python :results value table", "return [['a', 1], ['long', 22]]", "#+end_src" })
	wait(babel.execute())
	eq("| a    |  1 |", text()[5])
	eq("| long | 22 |", text()[6])
	wait(babel.execute())
	eq(6, #text())
	for _, language in ipairs({ "lua", "javascript" }) do
		lines({ "#+begin_src " .. language .. " :results value :var x=21", "return x * 2", "#+end_src" })
		wait(babel.execute())
		eq(": 42", text()[5])
	end
	lines({ '#+begin_src sh :results output :var msg="olá mundo"', 'printf "%s\\n" "$msg"', "#+end_src" })
	wait(babel.execute())
	eq(": olá mundo", text()[5])
	lines({
		"#+begin_src python :session shared :results output",
		"x = 20",
		"#+end_src",
		"#+begin_src python :session shared :results value",
		"x + 22",
		"#+end_src",
	})
	local batch = babel.execute_all()
	assert(vim.wait(5000, function()
		return batch.done
	end, 10))
	eq(nil, batch.error)
	eq(2, #batch.jobs)
	eq(42, batch.jobs[2].result.value)
	eq(": 42", text()[#text()])
	eq(1, python.reset("shared"))
	lines({
		"#+PROPERTY: header-args:python :results value :var x=1",
		"* Pai",
		":PROPERTIES:",
		":header-args:python: :var x=20",
		":END:",
		"#+name: herdado",
		"#+header: :var y=2",
		"#+begin_src python :var x=40",
		"return x + y",
		"#+end_src",
	})
	wait(babel.execute("herdado"))
	eq(": 42", text()[#text()])
	lines({
		"#+name: dados",
		"| 10 | 20 |",
		"|  5 |  7 |",
		"#+begin_src python :results value :var data=dados",
		"return sum(sum(row) for row in data)",
		"#+end_src",
	})
	vim.api.nvim_win_set_cursor(0, { 5, 0 })
	wait(babel.execute())
	eq(": 42", text()[#text()])
	lines({
		"#+name: helpers",
		"#+begin_src python :eval never",
		"def double(x):",
		"    return x * 2",
		"#+end_src",
		"#+begin_src python :noweb yes :results value",
		"<<helpers>>",
		"return double(21)",
		"#+end_src",
	})
	vim.api.nvim_win_set_cursor(0, { 7, 0 })
	wait(babel.execute())
	eq(": 42", text()[#text()])
	for _, format in ipairs({ "drawer", "code", "html", "org", "raw", "list" }) do
		lines({ "#+begin_src python :results value " .. format, "return 'ok'", "#+end_src" })
		wait(babel.execute())
		local count = #text()
		wait(babel.execute())
		eq(count, #text())
	end
	lines({ "#+begin_src python :results output append", "print('ok')", "#+end_src" })
	wait(babel.execute())
	wait(babel.execute())
	eq({ ": ok", ": ok" }, vim.list_slice(text(), 5))
	lines({ "#+begin_src python :results output silent", "print('ok')", "#+end_src" })
	wait(babel.execute())
	eq(3, #text())
	lines({ "#+begin_src python :results output file :file result.txt", "print('conteúdo')", "#+end_src" })
	wait(babel.execute())
	eq({ "conteúdo" }, vim.fn.readfile(tmp .. "/result.txt"))
	eq("[[file:result.txt]]", text()[5])
	lines({ "#+begin_src python :session timeout :results output", "import time; time.sleep(5)", "#+end_src" })
	babel.config.timeout_ms = 100
	local session_timeout = wait(babel.execute())
	eq(124, session_timeout.result.code)
	eq(0, python.reset("timeout"))
	babel.config.timeout_ms = 10000
	local fixtures = {
		{ "#+begin_src python :results value table", "return False", "#+end_src" },
		{ "#+begin_src python :results value list", "return False", "#+end_src" },
		{ "#+begin_src python :results output table", "print('1\\t2')", "print('3\\t4')", "#+end_src" },
		{ "#+begin_src python :results value :wrap no", "return 'ok'", "#+end_src" },
		{
			"#+name: data",
			"| name | score |",
			"|------+-------|",
			"| A | 1 |",
			"| B | 2 |",
			"#+begin_src python :results value table :var x=data :colnames yes",
			"return x",
			"#+end_src",
		},
		{ "#+begin_src python", "return 42", "#+end_src" },
		{ "#+begin_src python", "1+1", "#+end_src" },
		{ "#+begin_src python :session last-expression", "x=21", "x*2", "#+end_src" },
		{ "#+begin_src lua :results value :var x=21", "return x*2", "#+end_src" },
		{ "#+begin_src js :results value :var x=21", "return x*2;", "#+end_src" },
		{ "#+begin_src sh :results output", "echo 42", "#+end_src" },
		{
			"#+name: data",
			"| name | score |",
			"|------+-------|",
			"| A | 1 |",
			"| B | 2 |",
			"#+begin_src python :results value table :var x=data",
			"return x",
			"#+end_src",
		},
		{
			'#+begin_src python :results value :prologue "x=40" :epilogue "return x+2"',
			"pass",
			"#+end_src",
		},
		{
			"#+begin_src python :results value :wrap example",
			"return 'ok'",
			"#+end_src",
		},
		{
			"#+name: double",
			"#+begin_src python :results value :var x=1",
			"return x * 2",
			"#+end_src",
			"#+begin_src python :results value :var answer=double(x=21)",
			"return answer",
			"#+end_src",
		},
		{
			"#+name: double",
			"#+begin_src python :results value :var x=1",
			"return x * 2",
			"#+end_src",
			"#+begin_src python :results value :noweb yes",
			"return <<double(x=21)>>",
			"#+end_src",
		},
		{ "#+begin_src python :results output", "print(6 * 7)", "#+end_src" },
		{ "#+begin_src python :results value :var x=21", "return x * 2", "#+end_src" },
		{ "#+begin_src python :results value table", "return [['a', 1], ['long', 22]]", "#+end_src" },
		{
			"#+name: answer",
			"#+header: :var x=40",
			"#+begin_src python :results value :var y=2",
			"return x+y",
			"#+end_src",
		},
		{ "#+PROPERTY: header-args:python :results value :var x=42", "#+begin_src python", "return x", "#+end_src" },
		{
			"#+begin_src python :session ref :results output",
			"x=40",
			"#+end_src",
			"#+begin_src python :session ref :results value",
			"x+2",
			"#+end_src",
		},
		{
			"#+name: fragment",
			"#+begin_src python :eval never",
			"n=42",
			"#+end_src",
			"#+begin_src python :results value :noweb yes",
			"<<fragment>>",
			"return n",
			"#+end_src",
		},
		{ "#+begin_src python :results value list", "return [1, 2, 3]", "#+end_src" },
		{ "#+begin_src python :results output drawer", "print('olá')", "#+end_src" },
	}
	-- Named dependencies are evaluated without inserting extra result blocks.
	lines({ "#+begin_src python :results output", "print('never run')", "#+end_src" })
	eq(false, pcall(babel.execute, "missing"))
	eq(3, #text())
	lines({
		"#+name: double",
		"#+begin_src python :results value :var x=1",
		"return x*2",
		"#+end_src",
		"#+begin_src python :results value :var n=double(x=21)",
		"return n",
		"#+end_src",
	})
	vim.api.nvim_win_set_cursor(0, { 6, 0 })
	wait(babel.execute())
	eq(": 42", text()[#text()])
	eq(9, #text())
	lines({ "#+name: cycle", "#+begin_src python :results value :var x=cycle()", "return x", "#+end_src" })
	local cycle = babel.execute("cycle")
	assert(vim.wait(5000, function()
		return cycle.done
	end, 10))
	eq(1, cycle.result.code)
	eq(true, cycle.result.stderr:find("circular", 1, true) ~= nil)
	lines({
		"#+name: first",
		"#+begin_src python :session fifo :results output",
		"import time; time.sleep(0.1); x=41",
		"#+end_src",
		"#+name: second",
		"#+begin_src python :session fifo :results value",
		"x+1",
		"#+end_src",
	})
	local first, second = babel.execute("first"), babel.execute("second")
	wait(first)
	wait(second)
	eq(42, second.result.value)
	python.reset("fifo")
	local function collected(document)
		local output, index = {}, 1
		while index <= #document do
			if document[index]:lower():match("^%s*#%+results:") then
				local a, b = require("org_workbench.results").span(document, index - 1)
				local body = vim.list_slice(document, a + 2, b)
				if #body == 1 and body[1] == ": " then
					body = {}
				end
				output[#output + 1], index = body, b + 1
			else
				index = index + 1
			end
		end
		return output
	end
	assert(vim.fn.executable("emacs") == 1, "Install Emacs to run differential tests")
	babel.config.default_header_args = ":results value replace"
	for i, fixture in ipairs(fixtures) do
		python.reset()
		lines(fixture)
		local suite = babel.execute_all()
		assert(vim.wait(5000, function()
			return suite.done
		end, 10))
		eq(nil, suite.error)
		local source, target = tmp .. "/reference-" .. i .. ".org", tmp .. "/reference-" .. i .. ".out"
		vim.fn.writefile(fixture, source)
		local reference = vim.system(
			{ "emacs", "--batch", "-Q", "--script", root .. "/tests/emacs-reference.el", source, target },
			{ text = true, timeout = 20000 }
		):wait()
		assert(reference.code == 0, "Emacs fixture " .. i .. ": " .. (reference.stderr or ""))
		eq(collected(vim.fn.readfile(target)), collected(text()))
	end
	python.reset()
	local example = vim.fn.readfile(root .. "/examples/code.org")
	lines(example)
	local example_batch = babel.execute_all()
	assert(vim.wait(10000, function()
		return example_batch.done
	end, 10))
	eq(nil, example_batch.error)
	eq(true, #example_batch.jobs >= 10)
	python.reset()
	print("Emacs Org: " .. #fixtures .. " documentos comparados")
end
