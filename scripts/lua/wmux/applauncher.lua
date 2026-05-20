if hs or arg[1] == "karabiner" then
	return {
		browser = "open -a zen.app",
		terminal = "/Applications/kitty.app/Contents/MacOS/kitty --detach -1 -d '~'",
		qq = "open -a QQ.app",
		pdfviewer = "open -a sioyek.app",
		wechat = "open -a WeChat.app",
		menu = "open -a 'Alfred 5.app'",
	}
elseif hl or arg[1] == "keyd" then
	return {
		terminal = "kitty",
		browser = "zen || zen-browser",
		qq = "/home/dirichy/.local/bin/qq",
		wechat = "wechat-universal",
		menu = "wofi --show drun -i",
		pdfviewer = "/home/dirichy/.local/bin/sioyek",
	}
end
