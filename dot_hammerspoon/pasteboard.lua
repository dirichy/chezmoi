local M = {}
M.utiIdentifier = "com.hammerspoon.dirichy"
---@type string|number
M.currentRegister = '"'
M.RegisterCache = { ['"'] = {} }
M.registermodal = hs.hotkey.modal.new({ "cmd", "shift" }, "'")
M.pastemodal = hs.hotkey.modal.new()
function M.restore(uti, register, dontUpdateNumber)
	register = register or M.currentRegister
	M.RegisterCache[register] = uti
	if dontUpdateNumber then
		return
	end
	for i = 9, 1, -1 do
		M.RegisterCache[i] = M.RegisterCache[i - 1]
	end
	M.RegisterCache[0] = uti
end
M.pastemodal:bind({ "cmd" }, "v", function()
	if M.currentRegister ~= '"' then
		hs.pasteboard.writeAllData(M.RegisterCache[M.currentRegister])
	end
	M.pastemodal:exit()
	hs.eventtap.keyStroke({ "cmd" }, "v")
	M.currentRegister = '"'
end)
for i = 0, 9 do
	M.RegisterCache[i] = {}
	M.registermodal:bind({}, tostring(i), function()
		M.currentRegister = i
		hs.pasteboard.writeAllData(M.RegisterCache[i])
		M.registermodal:exit()
	end)
end
for i = string.byte("a"), string.byte("z") do
	M.RegisterCache[string.char(i)] = {}
	M.registermodal:bind({}, string.char(i), function()
		M.currentRegister = string.char(i)
		hs.pasteboard.writeAllData(M.RegisterCache[string.char(i)])
		M.registermodal:exit()
	end)
end
M.registermodal:bind({ "shift" }, "'", function()
	M.currentRegister = '"'
	hs.pasteboard.writeAllData(M.RegisterCache['"'])
	M.registermodal:exit()
end)
function M.exit()
	M.pastemodal:exit()
	M.registermodal:exit()
	M.currentRegister = '"'
end
M.pasteboardWatcher = hs.timer.new(0.25, function()
	local uti = hs.pasteboard.readAllData()
	if not uti then
		error("pasteboard is empty")
	end
	if uti[M.utiIdentifier] then
		return
	end
	M.restore(uti)
	uti[M.utiIdentifier] = "1"
	hs.pasteboard.writeAllData(uti)
	M.currentRegister = '"'
	M.exit()
end)
M.pasteboardWatcher:start()
function M.showAll()
	print(hs.inspect(M.RegisterCache))
end
return M
