-- Reminder/statistics behavior without a desktop, network, or real input-method state.
local repo, temporary = assert(arg[1]), assert(arg[2])
local root = repo .. "/dot_local/share/fcitx5/rime/lua/"
package.path = root .. "?.lua;" .. package.path
rime_api = { get_user_data_dir = function() return temporary end }
local commands = {}
os.execute = function(command) commands[#commands + 1] = command; return true end
io.popen = function() return { read = function() return "Linux" end, close = function() end } end

-- Generated-table correctness is covered by the offline Git integration test.
package.preload["tiger.simp_table"] = function() return { ["来"] = "a", ["如"] = "bb" } end
local tracker = require("tiger.simp_tracker")
local options = { simp_hint = false, simp_record = true }
local callback, disconnected
local context = {
	input = "ap",
	get_option = function(_, name) return options[name] end,
	get_commit_text = function() return "来" end,
	commit_notifier = { connect = function(_, func)
		callback = func
		return { disconnect = function() disconnected = true end }
	end },
}
local env = { engine = { context = context } }
tracker.init(env)
callback(context) -- Native commit: one event.
tracker.observe(env, "来", "ap") -- Manual commit: one event, caller avoids native notifier.
tracker.observe(env, "来", "a") -- Already short.
tracker.observe(env, "来", "b") -- Different same-length code is not overtyping.
tracker.observe(env, "来", "`lai") -- Reverse lookup.
tracker.observe(env, "来", ";d") -- Tool.
tracker.observe(env, "来去", "ap") -- Cannot align custom words: do not guess.
tracker.observe(env, "来如", "abcdbbcd") -- Fixed four-code continuous input.
local entries, failed = tracker.summary(env)
assert(not failed and #entries == 3)
assert(entries[1].char == "来" and entries[1].actual == "ap")
assert(entries[1].count == 2 and entries[1].extra == 2)
assert(#commands == 0)
local file = assert(io.open(temporary .. "/tiger-simp-stats.tsv", "r"))
local persisted = file:read("a")
file:close()
assert(not persisted:find("来如", 1, true)) -- Never saves whole text.
local event_count = 0
for _ in persisted:gmatch("\n") do event_count = event_count + 1 end
assert(event_count == 4)

options.simp_record = false
options.simp_hint = true
tracker.observe(env, "来", "ap")
assert(#commands == 1 and commands[1]:match("&$")) -- Async, not waiting for desktop notification.
assert(tracker.summary(env)[1].count == 2) -- Notification toggle independent from recording.
options.simp_hint = false
tracker.observe(env, "来", "ap")
assert(#commands == 1)

-- Simulate a restart and replay only valid event lines.
file = assert(io.open(temporary .. "/tiger-simp-stats.tsv", "a"))
file:write("truncated garbage\n")
file:close()
local restarted = dofile(root .. "tiger/simp_tracker.lua")
assert(restarted.summary(env)[1].count == 2)
tracker.fini(env)
assert(disconnected)

-- An unwritable statistics path does not prevent input/reminders from working.
rime_api.get_user_data_dir = function() return temporary .. "/does-not-exist" end
options.simp_record = true
tracker.observe(env, "来", "ap")
local _, write_failed = tracker.summary(env)
assert(write_failed)
print("Tiger shorthand: native/manual commits, continuous input, independent toggles and persistence passed")

-- Tiger repeat candidates and keystroke statistics use independent instance state.
local quick_input = require("quick_input")
local now = 1000
rime_api.get_time_ms = function() return now end
local function key(char, flags)
	flags = flags or {}
	local result = { keycode = string.byte(char) }
	for _, flag in ipairs({ "release", "ctrl", "alt", "super" }) do
		result[flag] = function() return flags[flag] or false end
	end
	return result
end
local function input_session()
	local output = {}
	local ctx = { input = "", caret_pos = 0, text = "" }
	function ctx:get_property() return "1" end
	function ctx:set_property() end
	function ctx:set_option() end
	function ctx:push_input(text) self.input = self.input .. text; self.caret_pos = #self.input end
	function ctx:get_option(name) return name == "ascii_mode" and self.ascii or false end
	function ctx:get_commit_text() return self.text end
	ctx.commit_history = { back = function() return ctx.history and { text = ctx.history } end }
	ctx.segments = {}
	ctx.composition = { toSegmentation = function()
		return { get_segments = function() return ctx.segments end }
	end }
	function ctx:clear() self.input, self.caret_pos = "", 0 end
	local instance = { engine = {
		schema = { schema_id = "tiger", config = { get_map = function() return nil end } },
		context = ctx,
		commit_text = function(_, text) output[#output + 1] = text; ctx.history = text end,
	} }
	quick_input.init(instance)
	return instance, ctx, output
end
local instance, ctx, output = input_session()
local function input(code, text, segments)
	ctx.input, ctx.caret_pos, ctx.text = code, #code, text or ""
	ctx.segments = {}
	for _, segment in ipairs(segments or {}) do
		ctx.segments[#ctx.segments + 1] = {
			start = segment[1], _end = segment[2],
			get_selected_candidate = function() return { type = segment[4] or "table", text = segment[3] } end,
		}
	end
end
ctx.history = "来"
local repeat_last = require("tiger.repeat_last")
Candidate = function(kind, start, finish, text, comment)
	return { type = kind, start = start, _end = finish, text = text, comment = comment }
end
yield = coroutine.yield
local function repeat_candidates(first_text, start, finish)
	start, finish = start or #ctx.input - 1, finish or #ctx.input
	local originals = {
		Candidate("table", start, finish, first_text or "组词", ""),
		Candidate("table", start, finish, "普通二选", ""),
	}
	local stream = { iter = function()
		local index = 0
		return function() index = index + 1; return originals[index] end
	end }
	local result = {}
	for candidate in coroutine.wrap(function() repeat_last(stream, instance) end) do
		result[#result + 1] = candidate
	end
	return result
end
input("z")
assert(repeat_candidates()[2].text == "来")
assert(repeat_candidates("来")[2].type == "repeat_last") -- Keep slot 2 even when slot 1 has the same text.
ctx.history = "选中" -- A native numeric selection.
assert(repeat_candidates()[2].text == "中")
input("abcdz", "来词组", { {0, 4, "来"}, {4, 5, "词组"} })
assert(repeat_candidates()[2].text == "来") -- Pending character takes priority over committed history.
assert(repeat_candidates("来", 0, 4)[2].type == "table") -- Earlier segments are untouched.
input("abcdefghz", "来如词组", { {0, 4, "来"}, {4, 8, "如"}, {8, 9, "词组"} })
assert(repeat_candidates()[2].text == "如")
input("abcdz", "")
assert(repeat_candidates()[2].type == "table") -- An untranslated prefix cannot supply a repeat.
input("abcd")
assert(repeat_candidates()[2].type == "table") -- Ordinary codes retain their candidate order.
ctx.history = nil
input("z")
assert(repeat_candidates()[2].type == "table") -- No history means no synthetic repeat.
ctx.history = "如"
local other, other_ctx, other_output = input_session()
assert(other_ctx.history == nil and ctx.history == "如")
other_ctx.input, other_ctx.caret_pos = "z", 1
assert(#other_output == 0)

-- Literal candidates remain visible; quick_input only intercepts their space/punctuation commits.
local observed = {}
tracker.observe = function(_, text, code) observed[#observed + 1] = { text, code } end
input("qqqq", "qqqq", { {0, 4, "qqqq", "raw"} })
local count = #output
assert(quick_input.func(key(" "), instance) == 1 and #output == count and ctx.input == "")
assert(quick_input.func(key(" "), instance) == 2) -- A plain space passes through immediately.
input("abcd", "来", { {0, 4, "来"} })
assert(quick_input.func(key(" "), instance) == 2 and ctx.input == "abcd") -- Normal selection stays native.
ctx.segments[#ctx.segments + 1] = { start = 4, _end = 4, get_selected_candidate = function() end }
assert(quick_input.func(key(" "), instance) == 2) -- An empty trailing segment is not a raw candidate.
input("qqqqabcd", "qqqq来", { {0, 4, "qqqq", "raw"}, {4, 8, "来"} })
assert(quick_input.func(key(" "), instance) == 1 and output[#output] == "来")
assert(observed[1][1] == "来" and observed[1][2] == "abcd")
input("lmnoqqqq", "Rimeqqqq", { {0, 4, "Rime"}, {4, 8, "qqqq", "raw"} })
assert(quick_input.func(key(" "), instance) == 1 and output[#output] == "Rime") -- Valid ASCII words are preserved.
for _, flag in ipairs({ "release", "ctrl", "alt", "super" }) do
	input("qqqq", "qqqq", { {0, 4, "qqqq", "raw"} })
	assert(quick_input.func(key(" ", { [flag] = true }), instance) == 2 and ctx.input == "qqqq")
end
input("qqqq", "qqqq", { {0, 4, "qqqq", "raw"} })
assert(quick_input.func(key("1"), instance) == 2 and ctx.input == "qqqq") -- Explicit numeric selection is native.

ctx.input, ctx.caret_pos = ";", 1
assert(quick_input.func(key("k"), instance) == 1 and instance.recording)
assert(not other.recording)
quick_input.func(key("a"), instance)
quick_input.func(key("a", { release = true }), instance)
quick_input.func(key("b"), instance)
quick_input.func(key(";"), instance)
now = now + 1000
ctx.input, ctx.caret_pos = ";", 1
assert(quick_input.func(key("k"), instance) == 1 and not instance.recording)
assert(output[#output] == "击键：3.0" and ctx.input == "")
for _, flag in ipairs({ "release", "ctrl", "alt", "super" }) do
	ctx.input, ctx.caret_pos = ";", 1
	assert(quick_input.func(key("k", { [flag] = true }), instance) == 2)
	assert(not instance.recording)
end
ctx.caret_pos = 0
assert(quick_input.func(key("k"), instance) == 2)
ctx.caret_pos, ctx.ascii = 1, true
assert(quick_input.func(key("k"), instance) == 2)
ctx.ascii = false
assert(quick_input.func(key("e"), instance) == 1 and output[#output] == ";e") -- Raw input through the dispatcher.
ctx.input, ctx.caret_pos = ";", 1
assert(quick_input.func(key("k"), instance) == 1)
ctx.input, ctx.caret_pos = ";", 1
assert(quick_input.func(key("k"), instance) == 1)
assert(not output[#output]:find("nan") and not output[#output]:find("inf"))
print("Tiger repeat candidates and ;k statistics: modifiers and instance isolation passed")
