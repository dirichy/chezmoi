local M = {}

local namespace = vim.api.nvim_create_namespace("LaterRelativeTime")

local function parse_time(parts, offset)
	return os.time({
		year = tonumber(parts[offset]),
		month = tonumber(parts[offset + 1]),
		day = tonumber(parts[offset + 2]),
		hour = tonumber(parts[offset + 3]),
		min = tonumber(parts[offset + 4]),
		sec = tonumber(parts[offset + 5]),
	})
end

local function parse_range(line)
	local parts = {
		line:match(
			"^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)%-(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)%s+"
		),
	}
	if #parts ~= 12 then
		return nil
	end
	return parse_time(parts, 1), parse_time(parts, 7)
end

local function approximate_duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds == 0 then
		return "now"
	end

	local units = {
		{ seconds = 86400, suffix = "d" },
		{ seconds = 3600, suffix = "h" },
		{ seconds = 60, suffix = "m" },
		{ seconds = 1, suffix = "s" },
	}
	local first_index = #units
	for index, unit in ipairs(units) do
		if seconds >= unit.seconds then
			first_index = index
			break
		end
	end

	local first = units[first_index]
	local first_count = math.floor(seconds / first.seconds)
	local remainder = seconds % first.seconds
	local second = units[first_index + 1]
	if not second or remainder == 0 then
		return first_count .. first.suffix
	end

	local second_count = math.ceil(remainder / second.seconds)
	local carry = first.seconds / second.seconds
	if second_count >= carry then
		return (first_count + 1) .. first.suffix
	end
	return first_count .. first.suffix .. second_count .. second.suffix
end

local function clear(buffer)
	if vim.api.nvim_buf_is_valid(buffer) then
		vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
	end
end

local function show(buffer)
	clear(buffer)
	if vim.bo[buffer].filetype ~= "later" then
		return
	end

	local row = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(buffer, row - 1, row, false)[1]
	local scheduled, deadline = parse_range(line or "")
	if not scheduled or not deadline then
		return
	end

	local until_start = scheduled - os.time()
	local start_text
	if until_start >= 0 then
		start_text = "in about " .. approximate_duration(until_start)
	else
		start_text = "about " .. approximate_duration(-until_start) .. " ago"
	end
	local window = "window about " .. approximate_duration(deadline - scheduled)
	vim.api.nvim_buf_set_extmark(buffer, namespace, row - 1, 0, {
		virt_text = { { "  󰔛 " .. start_text .. " · " .. window, "Comment" } },
		virt_text_pos = "eol",
		priority = 100,
	})
end

function M.setup()
	local group = vim.api.nvim_create_augroup("LaterRelativeTime", { clear = true })
	vim.api.nvim_create_autocmd("CursorHold", {
		group = group,
		callback = function(event)
			show(event.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave" }, {
		group = group,
		callback = function(event)
			clear(event.buf)
		end,
	})
end

M._approximate_duration = approximate_duration
M._parse_range = parse_range

return M
