local HOME = os.getenv("HOME") or "~"

if hs or arg and arg[1] == "karabiner" then
	return {
		browser = "open -a zen.app",
		terminal = "/Applications/kitty.app/Contents/MacOS/kitty --detach -1 -d '~'",
		filemgr = "/Applications/kitty.app/Contents/MacOS/kitty --detach -1 -d '~' yazi",
		qq = "open -a QQ.app",
		pdfviewer = "open -a sioyek.app",
		wechat = "open -a WeChat.app",
		menu = "open -a 'Alfred 5.app'",
	}
elseif hl or arg and arg[1] == "keyd" then
	return {
		terminal = "kitty",
		browser = "zen || zen-browser",
		filemgr = "kitty yazi",
		qq = HOME .. "/.local/bin/qq",
		wechat = "wechat-universal",
		menu = "wofi --show drun -i",
		pdfviewer = HOME .. "/.local/bin/sioyek",
	}
end
return {}
