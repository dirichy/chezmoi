## Rime-ice 配置：
### 下载Rime-ice 到 对应前端的用户目录，

| 前端 |用户目录|
|-------|-------|
|鼠须管 |~/Library/Rime/|
|fcitx-rime |~/.local/share/fcitx5/rime|
### 修改Rime-ice 的配置

后端配置在用户目录下的 default.yaml 中； 鼠须管前端配置在squirrel.yaml, squirrel.custom.yaml

修改配置后，重新部署才生效。
linux 重新部署的命令为 
``` bash 
fcitx5-remote -r
```
若部署不成功尝试reboot。

## keyd 配置:
keyd 是linux 上的键位映射软件。配置文件在/etc/keyd, 
安装之后启动
```bash 
systemctl enable --now keyd
```
修改之后需要以下命令才生效。
```bash
sudo keyd reload
```
若配置文件在其他位置，需要需要软链到/etc/keyd，
```bash 
sudo ln -s /path/to/dotfiles/keyd /etc/keyd
```
## 如何用 Karabiner ：
Karabiner 是mac上的键位映射软件。配置文件在~/.config/karabiner，
其中，Karabiner.json 运行时文件，包括simple和complex的键位映射。但是不好开启或关闭具体功能。

可以将具体的功能/模块单独放一个文件在Karabiner 的配置的如下文件中
~/.config/karabiner/assets/complex_modifications/ 
然后通过app界面加入该功能，选择开启或者关闭这个功能。

### 写一个具体的键位映射
在每一个键位映射是表格maniplitors的元素，按规则添加condition，from，to。
