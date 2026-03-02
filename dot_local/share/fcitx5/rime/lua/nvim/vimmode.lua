local function get_vim_mode(input, seg, env)
	if input == "/mode" then
		local pipe = io.popen("/opt/homebrew/bin/socat - /tmp/vimmode")
		if not pipe then
			yield(Candidate("mode", seg.start, seg._end, "vimmode" .. "fuck", ""))
			return
		end
		local data = pipe:read("*l")
		yield(Candidate("mode", seg.start, seg._end, "vimmode" .. tostring(data), ""))
		-- local client = uv.new_pipe(false)
		--
		-- -- 连接到 Unix 套接字
		-- client:connect(socket_path, function(err)
		-- 	if err then
		-- 		print("Failed to connect to socket:", err)
		-- 		return
		-- 	end
		-- 	print("Connected to socket:", socket_path)
		--
		-- 	-- 从套接字读取数据并打印到标准输出
		-- 	client:read_start(function(err, data)
		-- 		assert(not err, err)
		-- 		if data then
		-- 			yield(Candidate("mode", seg.start, seg._end, "vimmode" .. data, ""))
		-- 		else
		-- 		end
		-- 	end)
		-- end)
		--
		-- -- 启动事件循环
		-- uv.run()
	end
end
return get_vim_mode
