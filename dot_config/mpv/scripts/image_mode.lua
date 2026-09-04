local mp = require("mp")
local msg = require("mp.msg")
local options = require("mp.options")
local utils = require("mp.utils")
local assdraw = require("mp.assdraw")

local opts = {
	image_exts = "avif,bmp,gif,heic,heif,j2k,jp2,jpeg,jpg,jxl,pbm,pgm,png,ppm,qoi,svg,tga,tif,tiff,webp",
	load_directory = true,
	slideshow_step = 1,
	pan_pixels = 50,
	zoom_step = 0.25,
	overlay_duration = 2000,
	editor_cmd = "xdg-open",
	crop_cmd = "magick",
	crop_suffix = "-crop",
	crop_min_pixels = 4,
}

options.read_options(opts, "image_mode")

local image_ext = {}
for ext in opts.image_exts:gmatch("[^,%s]+") do
	image_ext[ext:lower()] = true
end

local active = false
local overlay = false
local loaded_dir_for = nil
local scaling_mode = 1
local scaling_modes = { "fit", "crop", "actual" }
local slideshow_delay = 0
local slideshow_timer = nil
local reset_timer = nil
local saved_properties = nil
local drag_cleanup = nil
local crop_overlay = mp.create_osd_overlay("ass-events")
local crop_mode = false
local crop_selection = nil
local crop_dragging = false
local refresh_overlay

local function path_ext(path)
	return path and path:match("%.([^./\\]+)$")
end

local function is_image(path)
	local ext = path_ext(path)
	return ext and image_ext[ext:lower()] or false
end

local function current_path()
	return mp.get_property("path")
end

local function playlist_count()
	return mp.get_property_number("playlist-count", 0)
end

local function playlist_pos()
	return mp.get_property_number("playlist-pos", 0)
end

local function show(text, duration)
	mp.osd_message(text, duration or opts.overlay_duration / 1000)
end

local function clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

local function save_properties()
	if saved_properties then
		return
	end
	saved_properties = {
		osc = mp.get_property("osc"),
		loop_playlist = mp.get_property("loop-playlist"),
		image_display_duration = mp.get_property("image-display-duration"),
		hwdec = mp.get_property("hwdec"),
	}
end

local function restore_properties()
	if not saved_properties then
		return
	end
	mp.set_property("osc", saved_properties.osc or "yes")
	mp.set_property("loop-playlist", saved_properties.loop_playlist or "no")
	mp.set_property("image-display-duration", saved_properties.image_display_duration or "1")
	mp.set_property("hwdec", saved_properties.hwdec or "auto")
	saved_properties = nil
end

local function reset_view()
	mp.command("no-osd set video-align-x 0; no-osd set video-align-y 0; no-osd set video-pan-x 0; no-osd set video-pan-y 0; no-osd set video-zoom 0; no-osd set panscan 0; no-osd set video-unscaled no")
	scaling_mode = 1
end

local function schedule_reset_view()
	if reset_timer then
		reset_timer:kill()
	end
	reset_timer = mp.add_timeout(0.05, function()
		reset_timer = nil
		if active then
			reset_view()
			refresh_overlay()
		end
	end)
end

local function center()
	mp.command("no-osd set video-align-x 0; no-osd set video-align-y 0; no-osd set video-pan-x 0; no-osd set video-pan-y 0")
end

local function actual_size()
	mp.command("no-osd set video-unscaled yes; no-osd set video-zoom 0; no-osd set panscan 0")
	scaling_mode = 3
	show("actual size")
end

local function apply_scaling()
	local mode = scaling_modes[scaling_mode]
	if mode == "fit" then
		mp.command("no-osd set video-unscaled no; no-osd set video-zoom 0; no-osd set panscan 0")
	elseif mode == "crop" then
		mp.command("no-osd set video-unscaled no; no-osd set video-zoom 0; no-osd set panscan 1")
	elseif mode == "actual" then
		mp.command("no-osd set video-unscaled yes; no-osd set video-zoom 0; no-osd set panscan 0")
	end
	center()
	show("scaling: " .. mode)
end

local function next_scaling()
	scaling_mode = scaling_mode % #scaling_modes + 1
	apply_scaling()
end

local function update_title()
	if not active then
		return
	end
	local title = mp.get_property("filename", "")
	local count = playlist_count()
	if count > 1 then
		title = string.format("[%d/%d] %s", playlist_pos() + 1, count, title)
	end
	mp.set_property("title", title)
end

local function overlay_text()
	local path = current_path() or ""
	local name = mp.get_property("filename", path)
	local count = playlist_count()
	local pos = playlist_pos() + 1
	local zoom = mp.get_property_number("video-zoom", 0)
	local scale = scaling_modes[scaling_mode]
	if count > 1 then
		return string.format("%d/%d  %s\nzoom %.2f  %s\n%s", pos, count, name, zoom, scale, path)
	end
	return string.format("%s\nzoom %.2f  %s\n%s", name, zoom, scale, path)
end

refresh_overlay = function()
	if active and overlay then
		show(overlay_text(), 3600)
	end
end

local function toggle_overlay()
	overlay = not overlay
	if overlay then
		refresh_overlay()
	else
		mp.osd_message("")
	end
end

local function print_current()
	local path = current_path() or ""
	msg.info(path)
	show(path)
end

local function absolute_path(path)
	if not path or path == "" or path:find("://", 1, true) or path:sub(1, 1) == "/" then
		return path
	end
	local working_directory = mp.get_property("working-directory")
	if working_directory and working_directory ~= "" then
		return utils.join_path(working_directory, path)
	end
	return path
end

local function open_in_editor()
	local path = absolute_path(current_path())
	local editor = tostring(opts.editor_cmd or "")
	if not path or path == "" then
		show("no image")
		return
	end
	if editor == "" then
		show("editor_cmd is empty")
		return
	end

	mp.command_native_async({
		name = "subprocess",
		args = { editor, path },
		playback_only = false,
	}, function(success, _, error_text)
		if not success then
			show("editor failed: " .. tostring(error_text))
		end
	end)
	show("edit: " .. editor)
end

local function remove_crop_overlay()
	crop_overlay:remove()
end

local function stop_crop_drag()
	crop_dragging = false
	mp.remove_key_binding("image-mode-crop-mouse-move")
end

local function video_rect()
	local dim = mp.get_property_native("osd-dimensions")
	if not dim then
		return nil
	end
	local w = dim.w - dim.ml - dim.mr
	local h = dim.h - dim.mt - dim.mb
	if w <= 0 or h <= 0 then
		return nil
	end
	return {
		x1 = dim.ml,
		y1 = dim.mt,
		x2 = dim.ml + w,
		y2 = dim.mt + h,
		w = w,
		h = h,
	}
end

local function image_size()
	local params = mp.get_property_native("video-params")
	if type(params) ~= "table" then
		return nil
	end
	local w = tonumber(params.w or params.dw)
	local h = tonumber(params.h or params.dh)
	if not w or not h or w <= 0 or h <= 0 then
		return nil
	end
	return { w = w, h = h }
end

local function crop_rect_screen()
	if not crop_selection then
		return nil
	end
	local rect = video_rect()
	if not rect then
		return nil
	end
	local x1 = clamp(math.min(crop_selection.x1, crop_selection.x2), rect.x1, rect.x2)
	local y1 = clamp(math.min(crop_selection.y1, crop_selection.y2), rect.y1, rect.y2)
	local x2 = clamp(math.max(crop_selection.x1, crop_selection.x2), rect.x1, rect.x2)
	local y2 = clamp(math.max(crop_selection.y1, crop_selection.y2), rect.y1, rect.y2)
	if x2 - x1 < 1 or y2 - y1 < 1 then
		return nil
	end
	return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

local function crop_rect_image()
	local screen = crop_rect_screen()
	local rect = video_rect()
	local size = image_size()
	if not screen or not rect or not size then
		return nil
	end

	local x = math.floor((screen.x1 - rect.x1) / rect.w * size.w + 0.5)
	local y = math.floor((screen.y1 - rect.y1) / rect.h * size.h + 0.5)
	local w = math.floor((screen.x2 - screen.x1) / rect.w * size.w + 0.5)
	local h = math.floor((screen.y2 - screen.y1) / rect.h * size.h + 0.5)

	x = clamp(x, 0, size.w - 1)
	y = clamp(y, 0, size.h - 1)
	w = clamp(w, 1, size.w - x)
	h = clamp(h, 1, size.h - y)
	return { x = x, y = y, w = w, h = h }
end

local function draw_crop_overlay()
	if not crop_mode then
		remove_crop_overlay()
		return
	end

	local ass = assdraw.ass_new()
	local screen = crop_rect_screen()
	if screen then
		ass:new_event()
		ass:append("{\\an7\\bord0\\shad0\\1c&HFFFFFF&\\alpha&H80&}")
		ass:draw_start()
		ass:rect_cw(screen.x1, screen.y1, screen.x2, screen.y2)
		ass:draw_stop()
		ass:new_event()
		ass:append("{\\an7\\bord2\\shad0\\1c&H00FFFF&\\3c&H000000&}")
		ass:draw_start()
		ass:move_to(screen.x1, screen.y1)
		ass:line_to(screen.x2, screen.y1)
		ass:line_to(screen.x2, screen.y2)
		ass:line_to(screen.x1, screen.y2)
		ass:line_to(screen.x1, screen.y1)
		ass:draw_stop()
	end
	ass:new_event()
	ass:pos(20, 20)
	ass:append("{\\bord2\\shad0}crop: drag mouse, Enter save, Esc cancel")
	crop_overlay.data = ass.text
	crop_overlay:update()
end

local function crop_output_path(path)
	local dir, filename = utils.split_path(path)
	local stem, ext = filename:match("^(.*)(%.[^.]*)$")
	if not stem then
		stem = filename
		ext = ".png"
	end
	local candidate = utils.join_path(dir, stem .. opts.crop_suffix .. ext)
	local index = 2
	while utils.file_info(candidate) do
		candidate = utils.join_path(dir, stem .. opts.crop_suffix .. "-" .. tostring(index) .. ext)
		index = index + 1
	end
	return candidate
end

local function save_crop()
	if not crop_mode then
		return
	end
	local path = absolute_path(current_path())
	local crop = crop_rect_image()
	local min_pixels = tonumber(opts.crop_min_pixels) or 4
	if not path or path == "" or not crop or crop.w < min_pixels or crop.h < min_pixels then
		show("crop: selection too small")
		return
	end
	if mp.get_property_number("video-rotate", 0) % 360 ~= 0 then
		show("crop: reset rotation first")
		return
	end

	local output = crop_output_path(path)
	local geometry = string.format("%dx%d+%d+%d", crop.w, crop.h, crop.x, crop.y)
	mp.command_native_async({
		name = "subprocess",
		args = { opts.crop_cmd, path, "-auto-orient", "-crop", geometry, "+repage", output },
		playback_only = false,
	}, function(success, _, error_text)
		if success then
			crop_mode = false
			crop_selection = nil
			stop_crop_drag()
			remove_crop_overlay()
			show("crop saved: " .. output)
		else
			show("crop failed: " .. tostring(error_text))
		end
	end)
end

local function cancel_crop(silent)
	local was_active = crop_mode
	crop_mode = false
	stop_crop_drag()
	crop_selection = nil
	remove_crop_overlay()
	if was_active and not silent then
		show("crop canceled")
	end
end

local function toggle_crop_mode()
	crop_mode = not crop_mode
	crop_dragging = false
	crop_selection = nil
	if crop_mode then
		draw_crop_overlay()
	else
		cancel_crop(true)
	end
end

local function crop_drag(e)
	if not crop_mode then
		return false
	end
	local x, y = mp.get_mouse_pos()
	if e.event == "down" then
		crop_dragging = true
		crop_selection = { x1 = x, y1 = y, x2 = x, y2 = y }
		mp.add_forced_key_binding("mouse_move", "image-mode-crop-mouse-move", function()
			if crop_mode and crop_dragging and crop_selection then
				local move_x, move_y = mp.get_mouse_pos()
				crop_selection.x2 = move_x
				crop_selection.y2 = move_y
				draw_crop_overlay()
			end
		end)
		draw_crop_overlay()
	elseif e.event == "up" then
		stop_crop_drag()
		if crop_selection then
			crop_selection.x2 = x
			crop_selection.y2 = y
		end
		draw_crop_overlay()
	end
	return true
end

local function pan(axis, pixels)
	local dim = mp.get_property_native("osd-dimensions")
	if not dim then
		return
	end
	local prop = "video-pan-" .. axis
	local size = axis == "x" and (dim.w - dim.ml - dim.mr) or (dim.h - dim.mt - dim.mb)
	if size == 0 then
		return
	end
	mp.set_property_number(prop, mp.get_property_number(prop, 0) + pixels / size)
end

local function stop_drag()
	if drag_cleanup then
		drag_cleanup()
		drag_cleanup = nil
	end
end

local function drag_to_pan(e)
	if crop_drag(e) then
		return
	end
	stop_drag()
	if not e or e.event ~= "down" then
		return
	end
	local dim = mp.get_property_native("osd-dimensions")
	if not dim then
		return
	end
	local start_x, start_y = mp.get_mouse_pos()
	local start_pan_x = mp.get_property_number("video-pan-x", 0)
	local start_pan_y = mp.get_property_number("video-pan-y", 0)
	local video_w = dim.w - dim.ml - dim.mr
	local video_h = dim.h - dim.mt - dim.mb
	if video_w == 0 or video_h == 0 then
		return
	end
	local moved = true
	local idle = function()
		if not moved then
			return
		end
		local x, y = mp.get_mouse_pos()
		mp.command(
			"no-osd set video-pan-x "
				.. (start_pan_x + (x - start_x) / video_w)
				.. "; no-osd set video-pan-y "
				.. (start_pan_y + (y - start_y) / video_h)
		)
		moved = false
	end
	mp.register_idle(idle)
	mp.add_forced_key_binding("mouse_move", "image-mode-mouse-move", function()
		moved = true
	end)
	drag_cleanup = function()
		mp.unregister_idle(idle)
		mp.remove_key_binding("image-mode-mouse-move")
	end
end

local function zoom(amount)
	mp.commandv("script-binding", "mouse_pan/cursor-centric-zoom", tostring(amount))
end

local function goto_index(index)
	local count = playlist_count()
	if count == 0 then
		return
	end
	if index < 0 then
		index = count - 1
	end
	mp.set_property_number("playlist-pos", math.max(0, math.min(index, count - 1)))
end

local function close_current()
	if playlist_count() <= 1 then
		mp.command("quit")
	else
		mp.commandv("playlist-remove", "current")
	end
end

local function slideshow_tick()
	if active and slideshow_delay > 0 then
		mp.command("playlist-next")
	end
end

local function set_slideshow(delta)
	slideshow_delay = math.max(0, slideshow_delay + delta)
	if slideshow_timer then
		slideshow_timer:kill()
		slideshow_timer = nil
	end
	if slideshow_delay > 0 then
		slideshow_timer = mp.add_periodic_timer(slideshow_delay, slideshow_tick)
		show("slideshow: " .. slideshow_delay .. "s")
	else
		show("slideshow: off")
	end
end

local function sorted_image_files(dir)
	local files = utils.readdir(dir, "files")
	if not files then
		return nil
	end
	table.sort(files, function(a, b)
		return a:lower() < b:lower()
	end)
	local images = {}
	for _, file in ipairs(files) do
		if is_image(file) then
			images[#images + 1] = utils.join_path(dir, file)
		end
	end
	return images
end

local function load_directory_images(path)
	if not opts.load_directory or playlist_count() ~= 1 or not path or path:find("://", 1, true) then
		return
	end
	local dir, file = utils.split_path(path)
	if not dir or dir == "" or loaded_dir_for == dir then
		return
	end
	local images = sorted_image_files(dir)
	if not images or #images <= 1 then
		return
	end
	loaded_dir_for = dir
	local current_abs = utils.join_path(dir, file)
	local current_index = nil
	for i, image in ipairs(images) do
		if image == current_abs then
			current_index = i
			break
		end
	end
	if not current_index then
		return
	end
	for i = current_index + 1, #images do
		mp.commandv("loadfile", images[i], "append")
	end
	for i = 1, current_index - 1 do
		mp.commandv("loadfile", images[i], "append")
	end
end

local bindings = {
	{ "q", "quit", function()
		if crop_mode then
			cancel_crop()
		else
			mp.command("quit")
		end
	end },
	{ "ESC", "quit-escape", function()
		if crop_mode then
			cancel_crop()
		else
			mp.command("quit")
		end
	end },
	{ "LEFT", "previous", function() mp.command("playlist-prev") end, { repeatable = true } },
	{ "[", "previous-bracket", function() mp.command("playlist-prev") end, { repeatable = true } },
	{ "RIGHT", "next", function() mp.command("playlist-next") end, { repeatable = true } },
	{ "]", "next-bracket", function() mp.command("playlist-next") end, { repeatable = true } },
	{ "n", "next-n", function() mp.command("playlist-next") end, { repeatable = true } },
	{ "N", "previous-n", function() mp.command("playlist-prev") end, { repeatable = true } },
	{ "ctrl+d", "next-half-page", function() mp.command("playlist-next") end, { repeatable = true } },
	{ "ctrl+u", "previous-half-page", function() mp.command("playlist-prev") end, { repeatable = true } },
	{ "g", "first", function() goto_index(0) end },
	{ "G", "last", function() goto_index(-1) end },
	{ "h", "pan-left", function() pan("x", opts.pan_pixels) end, { repeatable = true } },
	{ "j", "pan-down", function() pan("y", -opts.pan_pixels) end, { repeatable = true } },
	{ "k", "pan-up", function() pan("y", opts.pan_pixels) end, { repeatable = true } },
	{ "l", "pan-right", function() pan("x", -opts.pan_pixels) end, { repeatable = true } },
	{ "H", "previous-large", function() mp.command("playlist-prev") end, { repeatable = true } },
	{ "L", "next-large", function() mp.command("playlist-next") end, { repeatable = true } },
	{ "UP", "zoom-in-up", function() zoom(opts.zoom_step) end, { repeatable = true } },
	{ "i", "zoom-in", function() zoom(opts.zoom_step) end, { repeatable = true } },
	{ "+", "zoom-in-plus", function() zoom(opts.zoom_step) end, { repeatable = true } },
	{ "DOWN", "zoom-out-down", function() zoom(-opts.zoom_step) end, { repeatable = true } },
	{ "o", "zoom-out", function() zoom(-opts.zoom_step) end, { repeatable = true } },
	{ "-", "zoom-out-minus", function() zoom(-opts.zoom_step) end, { repeatable = true } },
	{ "z", "center-z", center },
	{ "0", "reset-0", function() reset_view(); show("reset") end },
	{ "c", "center", center },
	{ "a", "actual-size", actual_size },
	{ "r", "reset", function() reset_view(); show("reset") end },
	{ "ctrl+r", "rotate", function() mp.commandv("script-binding", "mouse_pan/rotate-video", "90") end },
	{ "s", "scaling", next_scaling },
	{ "S", "upscaling", function()
		mp.command("cycle-values scale bilinear nearest")
		show("upscaling: " .. mp.get_property("scale", ""))
	end },
	{ "x", "close", close_current },
	{ "f", "fullscreen", function() mp.command("cycle fullscreen") end },
	{ "d", "overlay", toggle_overlay },
	{ "e", "edit", open_in_editor },
	{ "v", "crop-mode", toggle_crop_mode },
	{ "ENTER", "crop-save", save_crop },
	{ "KP_ENTER", "crop-save-kp", save_crop },
	{ "p", "print", print_current },
	{ ".", "next-frame", function() mp.command("frame-step") end },
	{ "SPACE", "play-pause", function() mp.command("cycle pause") end },
	{ "t", "slideshow-up", function() set_slideshow(opts.slideshow_step) end },
	{ "T", "slideshow-down", function() set_slideshow(-opts.slideshow_step) end },
	{ "MBTN_LEFT", "drag-to-pan", drag_to_pan, { complex = true } },
	{ "WHEEL_UP", "wheel-zoom-in", function() zoom(opts.zoom_step) end },
	{ "WHEEL_DOWN", "wheel-zoom-out", function() zoom(-opts.zoom_step) end },
}

local function add_bindings()
	for _, binding in ipairs(bindings) do
		mp.add_forced_key_binding(binding[1], "image-mode-" .. binding[2], binding[3], binding[4])
	end
end

local function remove_bindings()
	for _, binding in ipairs(bindings) do
		mp.remove_key_binding("image-mode-" .. binding[2])
	end
end

local function set_active(value)
	if active == value then
		return
	end
	active = value
	if active then
		save_properties()
		add_bindings()
		mp.set_property("hwdec", "no")
		mp.set_property("image-display-duration", "inf")
		mp.set_property("loop-playlist", "inf")
		mp.set_property("osc", "no")
		reset_view()
	else
		remove_bindings()
		overlay = false
		cancel_crop(true)
		stop_drag()
		if reset_timer then
			reset_timer:kill()
			reset_timer = nil
		end
		if slideshow_timer then
			slideshow_timer:kill()
			slideshow_timer = nil
		end
		slideshow_delay = 0
		restore_properties()
	end
end

mp.register_event("file-loaded", function()
	local path = current_path()
	set_active(is_image(path))
	if active then
		schedule_reset_view()
		load_directory_images(path)
		update_title()
		refresh_overlay()
	end
end)

mp.observe_property("playlist-pos", "number", function()
	update_title()
	refresh_overlay()
end)

mp.observe_property("video-zoom", "number", refresh_overlay)
