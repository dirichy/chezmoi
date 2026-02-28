#!/usr/bin/env bash
# font
paru -S --needed noto-fonts-cjk linuxqq fuse
# rime
paru -S --needed fcitx5-rime fcitx5 fcitx5-configtool
# audio
paru -S --needed pipewire-audio pipewire-pulse wireplumber bluez bluez-utils blueman
sudo systemctl enable --now bluetooth
# util
paru -S --needed keyd chezmoi openssh autossh greetd github-cli wl-clipboard
sudo systemctl enable --now sshd greetd keyd
# util_network
paru -S --needed mihomo tailscale networkmanager
sudo systemctl enable --now NetworkManager
# util_gui
paru -S --needed kitty mpv zen-browser-bin wofi xorg-xrdb zathura sioyek 
# util_cli
paru -S --needed ffmpeg-full git gopass fzf zoxide thefuck ripgrep tree-sitter-cli unzip tar wget curl zsh uv tmux luarocks lua luajit imagemagick lsd fd
# language
paru -S --needed go ruby php julia cargo lua luajit lua51
# util_tui
paru -S --needed neovim vim yazi lazygit
# desktop
paru -S --needed hyprland hyprpaper waybar hypridle udisken sunshine socat ddcutil
sudo luarocks --lua-version=5.1 install luasocket lua-cjson luv
systemctl --user start hyprpaper waybar hypridle udisken sunshine
# latex
paru -S --needed texlive

