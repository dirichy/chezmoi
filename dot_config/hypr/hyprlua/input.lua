local M = {}
local xdg = os.getenv("XDG_RUNTIME_DIR")
local sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
local HYPR_SOCKET = xdg .. "/hypr/" .. sig .. "/.socket2.sock"
local uv = hypr.uv
local events = setmetatable({}, {
	__index = function(t, k)
		rawset(t, k, {})
		return t[k]
	end,
})
M.listen = setmetatable({}, {
	__call = function(self, evs, callback)
		evs = type(evs) == "table" and evs or { evs }
		for index, ev in ipairs(evs) do
			table.insert(events[ev], callback)
		end
	end,
	__index = function(t, k)
		rawset(t, k, function(...)
			return M.listen({ k }, ...)
		end)
		return t[k]
	end,
})
local function callback(ev, data)
	for index, f in ipairs(events[ev]) do
		print(ev, data)
		f(data)
	end
end

-- =========================
-- Hyprland Event Listener
-- =========================
local hypr_client = uv.new_pipe(false)
hypr_client:connect(HYPR_SOCKET, function(err)
	if err then
		print("Failed to connect Hyprland socket:", err)
		return
	end
	print("Connected to Hyprland event socket")
end)

-- 持续读取 Hyprland 事件
local buf = ""
hypr_client:read_start(function(err, data)
	if err then
		print("Hyprland read error:", err)
		return
	end
	if data then
		buf = buf .. data
		for line in buf:gmatch("([^\n]+)\n?") do
			local event, payload = line:match("([^>]+)>>(.+)")
			if event and payload then
				callback(event, payload)
				print("[Hyprland Event] ", event, payload)
			end
		end
		-- 保留未处理残余
		buf = buf:match("([^\n]*$)") or ""
	end
end)

return M
