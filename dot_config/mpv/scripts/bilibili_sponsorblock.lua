-- bilibili_sponsorblock_fixed.lua
--
-- mpv script for BilibiliSponsorBlock.
-- 自动获取并跳过 Bilibili 视频中的 SponsorBlock 片段。
--
-- 安装位置：
--   ~/.config/mpv/scripts/bilibili_sponsorblock.lua
--
-- 可选配置：
--   ~/.config/mpv/script-opts/bilibili_sponsorblock.conf
--
-- 本版本重点修复：
--   1. 用户暂停、缓存暂停或 seek 过程中不再触发自动跳转；
--   2. 每个片段进入一次只触发一个 seek，避免重复 seek 排队；
--   3. seek 完成前暂停周期检查，并设置超时保护；
--   4. 使用正确的组合 seek flag：absolute+exact；
--   5. 文件切换后忽略过期的异步网络回调；
--   6. 整理状态管理、计时器管理及日志输出。

local msg = require("mp.msg")
local utils = require("mp.utils")
local options = require("mp.options")

-- ---------------------------------------------------------------------------
-- 配置
-- ---------------------------------------------------------------------------

local opts = {
	-- BilibiliSponsorBlock API 地址。
	api_base = "https://bsbsb.top/api",

	-- 需要跳过的分类，使用逗号分隔。
	-- 常见值：sponsor,selfpromo,interaction,intro,outro,preview,music_offtopic
	categories = "sponsor",

	-- 需要执行的 action type，通常只保留 skip。
	action_types = "skip",

	-- 能检测到 cid 时，将 cid 发给 API 并在本地再次过滤。
	use_cid = true,

	-- 最低票数。API 通常已经做过过滤，此项只是本地保护。
	min_votes = -9999,

	-- 跳到片段结尾后再额外前进的秒数。
	end_offset = 0.15,

	-- 播放位置检查间隔。
	check_interval = 0.20,

	-- file-loaded 后等待一段时间再读取 yt-dlp 元数据。
	fetch_delay = 0.50,

	-- seek 模式：
	--   exact     精确，但网络流/长 GOP 视频上可能更慢；
	--   keyframes 更快，但落点可能不够精确。
	seek_mode = "exact",

	-- 发出 seek 后，最多等待多少秒解除内部 seek 锁。
	-- 正常情况下会由 playback-restart 更早解除。
	seek_guard_timeout = 5.0,

	-- 重新退回到片段起点之前多远时，允许该片段再次自动跳过。
	-- 这样用户主动回看时仍可再次触发，但 seek 失败时不会原地重复触发。
	rearm_margin = 0.50,

	-- curl 设置。
	curl_bin = "curl",
	connect_timeout = 3,
	max_time = 8,

	-- API 请求头。
	origin = "mpv://bilibili_sponsorblock",
	x_ext_version = "0.2.0",

	-- OSD 设置。
	osd = true,
	osd_duration = 2,

	-- 跳过后是否向 API 上报 viewedVideoSponsorTime。
	record_views = false,

	-- 启动时是否启用。
	enabled = true,
}

options.read_options(opts, "bilibili_sponsorblock")

-- ---------------------------------------------------------------------------
-- 运行状态
-- ---------------------------------------------------------------------------

local state = {
	-- 当前文件代数。切换文件后递增，用来使旧回调失效。
	generation = 0,

	-- 每次网络请求递增，用来使同一文件中的旧请求失效。
	request_token = 0,

	file_active = false,
	user_paused = false,
	cache_paused = false,
	seeking = false,
	seek_busy = false,

	bvid = nil,
	cid = nil,
	segments = {},
	loaded = false,
	loading = false,
}

-- 下方函数会引用这些 timer，因此先声明。
local check_timer
local load_timer
local seek_guard_timer

-- ---------------------------------------------------------------------------
-- 通用辅助函数
-- ---------------------------------------------------------------------------

local function notify(text, level)
	level = level or "info"

	local logger = msg[level] or msg.info
	logger(text)

	if opts.osd then
		mp.osd_message("BilibiliSponsorBlock: " .. tostring(text), tonumber(opts.osd_duration) or 2)
	end
end

local function kill_timer(timer)
	if timer then
		-- kill() 与 stop() 不同：kill() 会重置剩余时间。
		-- 恢复播放后不会因为保留了旧的 elapsed time 而立刻执行回调。
		timer:kill()
	end
end

local function urlencode(value)
	local str = tostring(value or "")
	return (
		str:gsub("\n", "\r\n"):gsub("([^%w%-_%.~])", function(char)
			return string.format("%%%02X", string.byte(char))
		end)
	)
end

local function json_escape(value)
	local str = tostring(value or "")
	return str:gsub("\\", "\\\\")
		:gsub('"', '\\"')
		:gsub("\b", "\\b")
		:gsub("\f", "\\f")
		:gsub("\n", "\\n")
		:gsub("\r", "\\r")
		:gsub("\t", "\\t")
end

local function split_csv(value)
	local result = {}

	for item in tostring(value or ""):gmatch("[^,%s]+") do
		result[#result + 1] = item
	end

	return result
end

local function list_to_set(list)
	local result = {}

	for _, value in ipairs(list) do
		result[value] = true
	end

	return result
end

local function categories_query_value()
	local categories = split_csv(opts.categories)
	if #categories == 0 then
		return nil
	end

	local encoded = {}
	for _, category in ipairs(categories) do
		encoded[#encoded + 1] = '"' .. json_escape(category) .. '"'
	end

	return "[" .. table.concat(encoded, ",") .. "]"
end

local function get_seek_flags()
	local mode = tostring(opts.seek_mode or "exact"):lower()

	if mode ~= "exact" and mode ~= "keyframes" then
		msg.warn("invalid seek_mode=" .. mode .. "; falling back to exact")
		mode = "exact"
	end

	-- mpv 的 seek command 只有一个 flags 参数；多个 flag 应使用 + 连接。
	return "absolute+" .. mode
end

-- ---------------------------------------------------------------------------
-- BV 号和 cid 检测
-- ---------------------------------------------------------------------------

local BVID_PATTERN = "BV[0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z]"
	.. "[0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z][0-9A-Za-z]"

local function find_bvid_in_string(value)
	if value == nil then
		return nil
	end

	return tostring(value):match(BVID_PATTERN)
end

local function find_cid_in_string(value)
	if value == nil then
		return nil
	end

	local str = tostring(value)
	return str:match("[?&]cid=(%d+)") or str:match("[?&]cid%%3D(%d+)") or str:match("cid=(%d+)")
end

local function detect_from_properties(finder)
	local properties = {
		"path",
		"stream-open-filename",
		"media-title",
		"metadata/by-key/webpage_url",
		"metadata/by-key/purl",
		"metadata/by-key/comment",
		"metadata/by-key/BVID",
		"metadata/by-key/bvid",
		"metadata/by-key/cid",
		"metadata/by-key/CID",
	}

	for _, property in ipairs(properties) do
		local hit = finder(mp.get_property(property))
		if hit then
			return hit
		end
	end

	local metadata = mp.get_property_native("metadata")
	if type(metadata) == "table" then
		for _, value in pairs(metadata) do
			local hit = finder(value)
			if hit then
				return hit
			end
		end
	end

	return nil
end

local function get_bvid()
	return detect_from_properties(find_bvid_in_string)
end

local function get_cid()
	return detect_from_properties(find_cid_in_string)
end

-- ---------------------------------------------------------------------------
-- API 请求
-- ---------------------------------------------------------------------------

local function api_base()
	return tostring(opts.api_base or "https://bsbsb.top/api"):gsub("/+$", "")
end

local function common_curl_args()
	return {
		opts.curl_bin,
		"-fsSL",
		"--connect-timeout",
		tostring(opts.connect_timeout),
		"--max-time",
		tostring(opts.max_time),
		"-A",
		"mpv-bilibili_sponsorblock/" .. tostring(opts.x_ext_version),
		"-H",
		"origin: " .. tostring(opts.origin),
		"-H",
		"x-ext-version: " .. tostring(opts.x_ext_version),
	}
end

local function build_skip_url(bvid, cid)
	local url = api_base() .. "/skipSegments?videoID=" .. urlencode(bvid)

	if opts.use_cid and cid and cid ~= "" then
		url = url .. "&cid=" .. urlencode(cid)
	end

	local categories = categories_query_value()
	if categories then
		url = url .. "&categories=" .. urlencode(categories)
	end

	return url
end

local function curl_get_json(url, callback)
	local args = common_curl_args()
	args[#args + 1] = url

	mp.command_native_async({
		name = "subprocess",
		args = args,
		capture_stdout = true,
		capture_stderr = true,
		playback_only = false,
	}, function(success, result, error_text)
		if not success then
			callback(nil, "subprocess failed: " .. tostring(error_text))
			return
		end

		result = result or {}
		if result.status ~= 0 then
			-- curl -f 在 HTTP 4xx 时通常返回 22。
			-- 该 API 可能用 404 表示没有数据，因此按空列表处理。
			if result.status == 22 then
				callback({}, nil)
			else
				callback(nil, "curl status " .. tostring(result.status) .. ": " .. tostring(result.stderr or ""))
			end
			return
		end

		local parsed, parse_error = utils.parse_json(result.stdout or "")
		if parsed == nil then
			callback(nil, "JSON parse failed: " .. tostring(parse_error))
			return
		end

		callback(parsed, nil)
	end)
end

local function curl_post_json(url, json_body)
	local args = common_curl_args()
	args[#args + 1] = "-H"
	args[#args + 1] = "content-type: application/json"
	args[#args + 1] = "-X"
	args[#args + 1] = "POST"
	args[#args + 1] = "--data-binary"
	args[#args + 1] = json_body
	args[#args + 1] = url

	mp.command_native_async({
		name = "subprocess",
		args = args,
		capture_stdout = true,
		capture_stderr = true,
		playback_only = false,
	}, function() end)
end

-- ---------------------------------------------------------------------------
-- 片段处理
-- ---------------------------------------------------------------------------

local function normalise_segments(raw_segments, current_cid)
	local result = {}
	local allowed_categories = list_to_set(split_csv(opts.categories))
	local allowed_actions = list_to_set(split_csv(opts.action_types))
	local has_category_filter = next(allowed_categories) ~= nil
	local has_action_filter = next(allowed_actions) ~= nil
	local min_votes = tonumber(opts.min_votes) or -9999

	if type(raw_segments) ~= "table" then
		return result
	end

	for _, item in ipairs(raw_segments) do
		if type(item) == "table" then
			local raw_segment = item.segment
			local start_time = raw_segment and tonumber(raw_segment[1])
			local end_time = raw_segment and tonumber(raw_segment[2])
			local category = tostring(item.category or "")
			local action = tostring(item.actionType or "")
			local votes = tonumber(item.votes or 0) or 0
			local item_cid = item.cid and tostring(item.cid) or nil

			local cid_ok = true
			if opts.use_cid and current_cid and item_cid then
				cid_ok = tostring(current_cid) == item_cid
			end

			local category_ok = not has_category_filter or allowed_categories[category] == true
			local action_ok = not has_action_filter or allowed_actions[action] == true

			if
				start_time
				and end_time
				and end_time > start_time
				and votes >= min_votes
				and cid_ok
				and category_ok
				and action_ok
			then
				result[#result + 1] = {
					start_time = start_time,
					end_time = end_time,
					uuid = tostring(item.UUID or ""),
					category = category,
					action = action,
					votes = votes,
					cid = item_cid,

					-- armed=false 表示本次进入该片段已经触发过 seek。
					-- 只有用户退回片段起点之前，才会重新置为 true。
					armed = true,
				}
			end
		end
	end

	table.sort(result, function(a, b)
		if a.start_time == b.start_time then
			return a.end_time < b.end_time
		end
		return a.start_time < b.start_time
	end)

	return result
end

local function record_viewed(uuid)
	if not opts.record_views or not uuid or uuid == "" then
		return
	end

	local body = '{"UUID":"' .. json_escape(uuid) .. '"}'
	curl_post_json(api_base() .. "/viewedVideoSponsorTime", body)
end

-- ---------------------------------------------------------------------------
-- Timer 和状态协调
-- ---------------------------------------------------------------------------

local function check_timer_should_run()
	return opts.enabled
		and state.file_active
		and state.loaded
		and #state.segments > 0
		and not state.user_paused
		and not state.cache_paused
		and not state.seeking
		and not state.seek_busy
end

local function update_check_timer()
	if not check_timer then
		return
	end

	-- 一律 kill 后再 resume，避免 stop/resume 保留旧的剩余时间。
	check_timer:kill()

	if check_timer_should_run() then
		check_timer:resume()
	end
end

local function clear_seek_guard()
	if seek_guard_timer then
		seek_guard_timer:kill()
		seek_guard_timer = nil
	end
end

local function finish_seek_guard()
	clear_seek_guard()
	state.seek_busy = false
	update_check_timer()
end

local function begin_seek_guard()
	clear_seek_guard()
	state.seek_busy = true
	update_check_timer()

	seek_guard_timer = mp.add_timeout(tonumber(opts.seek_guard_timeout) or 5.0, function()
		seek_guard_timer = nil

		if state.seek_busy then
			msg.warn("seek guard timed out; releasing auto-skip lock")
			state.seek_busy = false
			update_check_timer()
		end
	end)
end

local function cancel_pending_load()
	if load_timer then
		load_timer:kill()
		load_timer = nil
	end
end

local function reset_file_state()
	state.generation = state.generation + 1
	state.request_token = state.request_token + 1

	cancel_pending_load()
	clear_seek_guard()

	state.file_active = false
	state.seek_busy = false
	state.bvid = nil
	state.cid = nil
	state.segments = {}
	state.loaded = false
	state.loading = false

	update_check_timer()
end

-- ---------------------------------------------------------------------------
-- 加载 API 数据
-- ---------------------------------------------------------------------------

local function load_segments()
	if not opts.enabled or not state.file_active then
		return
	end

	state.request_token = state.request_token + 1
	local request_token = state.request_token
	local generation = state.generation

	state.loaded = false
	state.loading = false
	state.segments = {}
	state.bvid = get_bvid()
	state.cid = get_cid()
	update_check_timer()

	if not state.bvid then
		notify("没有在当前播放项中找到 BV 号", "debug")
		return
	end

	state.loading = true
	local url = build_skip_url(state.bvid, state.cid)
	msg.info("fetching segments: " .. url)

	curl_get_json(url, function(data, error_text)
		-- 文件已经切换，或者期间又发起了更新的请求：忽略旧回调。
		if generation ~= state.generation or request_token ~= state.request_token or not state.file_active then
			return
		end

		state.loading = false

		if error_text then
			notify("获取片段失败：" .. error_text, "warn")
			update_check_timer()
			return
		end

		state.segments = normalise_segments(data, state.cid)
		state.loaded = true
		update_check_timer()

		if #state.segments == 0 then
			notify("没有可跳过片段（" .. tostring(state.bvid) .. "）")
		else
			notify("已加载 " .. tostring(#state.segments) .. " 个片段（" .. tostring(state.bvid) .. "）")
		end
	end)
end

local function schedule_load(delay)
	cancel_pending_load()

	load_timer = mp.add_timeout(delay, function()
		load_timer = nil
		load_segments()
	end)
end

-- ---------------------------------------------------------------------------
-- 自动跳过
-- ---------------------------------------------------------------------------

local function perform_skip(segment)
	-- 先取消 armed，再发 seek。即使 seek 暂时失败，也不会每 0.2 秒重复排队。
	segment.armed = false

	local target = segment.end_time + (tonumber(opts.end_offset) or 0.15)
	local text = string.format("跳过 %s %.2f → %.2f", segment.category, segment.start_time, segment.end_time)

	begin_seek_guard()
	notify(text)

	-- mpv 的多个 seek flag 必须放在同一个参数中，例如 absolute+exact。
	local ok, error_text = pcall(mp.commandv, "seek", tostring(target), get_seek_flags())

	if not ok then
		notify("seek 命令失败：" .. tostring(error_text), "error")
		finish_seek_guard()
		return
	end

	record_viewed(segment.uuid)
end

local function check_skip()
	if not check_timer_should_run() then
		return
	end

	-- 再读取一次实时属性，防止属性通知尚未分发时出现竞态。
	if
		mp.get_property_bool("pause", false)
		or mp.get_property_bool("paused-for-cache", false)
		or mp.get_property_bool("seeking", false)
		or mp.get_property_bool("eof-reached", false)
	then
		return
	end

	local position = mp.get_property_number("time-pos")
	if not position then
		return
	end

	local rearm_margin = tonumber(opts.rearm_margin) or 0.50

	for _, segment in ipairs(state.segments) do
		-- 用户主动 seek 回片段起点之前时，允许之后再次自动跳过。
		if position < segment.start_time - rearm_margin then
			segment.armed = true
		end

		if segment.start_time > position then
			-- 已排序，后续片段的开始时间只会更大。
			break
		end

		if segment.armed and position >= segment.start_time and position < segment.end_time - 0.03 then
			perform_skip(segment)
			return
		end
	end
end

check_timer = mp.add_periodic_timer(
	tonumber(opts.check_interval) or 0.20,
	check_skip,
	true -- 初始禁用；由 update_check_timer() 统一管理。
)

-- ---------------------------------------------------------------------------
-- mpv 事件
-- ---------------------------------------------------------------------------

mp.register_event("file-loaded", function()
	reset_file_state()

	state.file_active = true
	state.user_paused = mp.get_property_bool("pause", false)
	state.cache_paused = mp.get_property_bool("paused-for-cache", false)
	state.seeking = mp.get_property_bool("seeking", false)

	if opts.enabled then
		schedule_load(tonumber(opts.fetch_delay) or 0.50)
	end
end)

mp.register_event("end-file", function()
	reset_file_state()
end)

-- seek 或解除暂停后，mpv 在真正重新开始输出音视频时触发该事件。
-- 如果这是脚本触发的自动 seek，则在这里解除 seek 锁。
mp.register_event("playback-restart", function()
	if state.seek_busy then
		finish_seek_guard()
	else
		update_check_timer()
	end
end)

-- 暂停时完全停止周期检查，恢复后从一个完整周期重新计时。
mp.observe_property("pause", "bool", function(_, value)
	state.user_paused = value == true
	update_check_timer()
end)

-- 缓存不足造成的暂停也不应触发 seek。
mp.observe_property("paused-for-cache", "bool", function(_, value)
	state.cache_paused = value == true
	update_check_timer()
end)

-- 用户手动 seek 或播放器内部 resync 时，暂停自动检查。
mp.observe_property("seeking", "bool", function(_, value)
	state.seeking = value == true

	-- 对脚本自己的 seek，优先等待 playback-restart；
	-- 对用户 seek，在 seeking=false 后恢复检查。
	update_check_timer()
end)

-- ---------------------------------------------------------------------------
-- 按键 / script-message
-- ---------------------------------------------------------------------------

mp.add_key_binding(nil, "bsb-toggle", function()
	opts.enabled = not opts.enabled

	if opts.enabled then
		notify("已启用")

		if state.file_active then
			load_segments()
		end
	else
		notify("已禁用")

		-- 使正在进行的请求回调失效。
		state.request_token = state.request_token + 1
		state.loading = false
		clear_seek_guard()
		state.seek_busy = false
		update_check_timer()
	end
end)

mp.add_key_binding(nil, "bsb-reload", function()
	if not state.file_active then
		notify("当前没有正在播放的文件", "warn")
		return
	end

	if not opts.enabled then
		notify("脚本当前已禁用", "warn")
		return
	end

	notify("重新加载片段")
	load_segments()
end)

mp.add_key_binding(nil, "bsb-list", function()
	if #state.segments == 0 then
		notify("当前没有片段")
		return
	end

	local lines = {}
	for index, segment in ipairs(state.segments) do
		lines[#lines + 1] = string.format(
			"%02d. %.2f-%.2f %s votes=%s",
			index,
			segment.start_time,
			segment.end_time,
			segment.category,
			tostring(segment.votes)
		)
	end

	mp.osd_message(table.concat(lines, "\n"), math.max(3, tonumber(opts.osd_duration) or 2))
end)
