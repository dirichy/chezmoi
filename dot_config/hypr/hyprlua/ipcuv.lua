local uv = hypr.uv

-- 配置
local TCP_PORT = 5555

-- =========================
-- TCP Server
-- =========================
local tcp_server = uv.new_tcp()
tcp_server:bind("0.0.0.0", TCP_PORT)
tcp_server:listen(128, function(err)
	assert(not err, err)
	local client = uv.new_tcp()
	tcp_server:accept(client)

	local chunks = {}
	client:read_start(function(err, data)
		if err then
			print("TCP read error:", err)
			client:close()
			return
		end
		if data then
			table.insert(chunks, data)
		else
			-- EOF
			local code = table.concat(chunks)
			if #code > 0 then
				local fn, err = load(code, "tcp", "t", _G)
				local res
				if not fn then
					res = "Compile error: " .. err
				else
					local ok, r = pcall(fn)
					if ok then
						res = tostring(r)
					else
						res = "Runtime error: " .. tostring(r)
					end
				end
				client:write(res .. "\n")
			end
			client:close()
		end
	end)
end)
print("TCP server listening on port", TCP_PORT)

-- =========================
-- 启动事件循环
-- =========================
uv.run()
