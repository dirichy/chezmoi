hs.g = hs.g or {}
hs.g.rusty = hs.eventtap.new({ hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp }, function(event)
	local type = event:getType()
	local keycode = event:getKeyCode()
	if keycode == hs.keycodes.map["space"] then
		if type == hs.eventtap.event.types.keyDown then
			hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, hs.mouse.absolutePosition()):post()
			return true
		elseif type == hs.eventtap.event.types.keyUp then
			hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, hs.mouse.absolutePosition()):post()
			return true
		end
	end
end)
hs.hotkey.bind({ "alt", "cmd" }, "r", function()
	if not hs.g.rusty:isEnabled() then
		hs.g.rusty:start()
		hs.alert("space as leftclick enabled!")
	else
		hs.g.rusty:stop()
		hs.alert("space as leftclick disabled!")
	end
end)
