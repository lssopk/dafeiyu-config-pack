# 大肥鱼唱歌插件

跟她说「给我唱首歌」「唱个生日歌」，她先回一句「等我开嗓」，过十几到四十秒发来一条语音：把现编的歌词唱出来，曲子从《小星星》《两只老虎》《生日快乐》里挑。

## Debian 13 / GNOME / SSH：本地 SoulX 服务器（可选）

默认豆包云端唱歌 **不需要** 单独启动此服务器。本节只适用于选择 `sing.backend=soulx` 的情况。

在 Debian 13 安装独立 Python 3.12 运行环境（不碰系统 Python 3.13）：

    sudo apt update
    sudo apt install -y git curl pipx
    pipx install uv
    # 若刚装好 uv，请重新登录或执行 ~/.local/bin/uv；确认命令可用后继续
    cd plugins/astrbot_plugin_dafeiyu_sing/sing_server
    bash setup_linux.sh
    bash start_sing_server.sh

默认安装位置为 `~/dafeiyu/sing`，也可以先设置 `DAFEIYU_SING_ROOT` 修改位置。
模型约 2.8 GB，依赖与 CUDA 版 PyTorch 另外占用磁盘空间。
建议 NVIDIA 驱动正常（`nvidia-smi`）时使用。
默认 URL `http://127.0.0.1:18620` 只允许宿主机访问。

如果 AstrBot **运行在 Docker**，无法通过容器内的 `127.0.0.1` 访问宿主机 SoulX。
本仓库的 Debian 13 Compose 已添加 `host.docker.internal:host-gateway` 映射。
高级用户可以查出宿主机的 Docker 网关 IPv4：

    ip -4 -o addr show docker0

然后以相应的 Docker 网关 IP 绑定 SoulX（例：`SING_HOST=172.17.0.1 bash start_sing_server.sh`），
在 AstrBot 插件里把 `server_url` 设置成 `http://host.docker.internal:18620`。
网关因主机 Docker 配置而异，必须确认容器可达；必要时检查防火墙。
**不要随意监听 0.0.0.0 并对公网开放 18620**，该 HTTP 唱歌服务未设置访问鉴权。
如果 AstrBot 原生运行在同一宿主机，保持默认 127.0.0.1 即可。

> Windows 仍按后面的 PowerShell 操作，不受 Linux 入口影响。

## 默认：豆包唱（不用另开服务）

默认用火山引擎的豆包 Seed Audio 1.0 在云端唱，凭证就是发语音用的那套（豆包语音的 APP ID 和 Access Token）。配置包导入时语音选 3，这个插件会一起装上，什么都不用另外配。

- 插件设置里「豆包语音 APP ID」「Access Token」留空，就借语音提供商「豆包 Seed Audio」那套；没用配置包的语音，也可以直接填在这里。
- 豆包**不会照原曲的调子唱**，唱的是她自己编的小调，偶尔像在哼。插件会核对唱出来的字：和歌词对不上八成就再抽一次（最多抽几次在「豆包最多抽几次」里改，默认 2）。
- 按生成的时长收费，1 元/分钟，一首十几到二十秒，一次两三毛。

## 可选：SoulX 唱（按谱唱，调子准，要 N 卡）

插件设置里「用哪个模型唱」改成 `soulx`，改用开源的歌声合成模型 [SoulX-Singer](https://github.com/Soul-AILab/SoulX-Singer)（Soul AI Lab 出品，Apache-2.0 协议）。它按谱子唱，调子是准的，但要在你自己的电脑上跑一个唱歌服务：

- 一张 NVIDIA 显卡，显存 6 GB 以上就够（RTX 4060 笔记本版实测可用）。没有独显也能跑，但一首歌要等好几分钟。
- 硬盘留出大约 8 GB：模型 2.8 GB，PyTorch 运行环境 5 GB 左右。
- 用配置包导入的，把 `settings/pack.json` 里 `sing.backend` 改成 `soulx` 再导入一次，就不会被盖回 `doubao`。

**第一步，装唱歌服务。** 在 `sing_server` 文件夹里右键 `setup_windows.ps1` →「使用 PowerShell 运行」。它会新建一个独立的 Python 环境（不碰 AstrBot 自己的环境），下载 SoulX-Singer 源码、模型和带显卡加速的 PyTorch。默认装到 `D:\dafeiyu\sing`，想换位置就用 `-Root 你的目录` 参数。国内网络下模型走 hf-mirror 镜像。

**第二步，启动唱歌服务。** 双击 `start_sing_server.bat`，看到 `listening on http://127.0.0.1:18620` 就是好了。这个窗口要一直开着，关了她就唱不了歌（会说嗓子哑了）。

**第三步，装插件。** 用配置包的一键导入工具装，或者把整个 `astrbot_plugin_dafeiyu_sing` 文件夹复制到 AstrBot 的 `data\plugins\` 里，再到 WebUI 的插件页点「重载」。

唱歌服务和 AstrBot 不在同一台电脑上也行：服务启动时加 `--host 0.0.0.0`，再在插件设置里把「唱歌服务地址」改成那台电脑的局域网地址。

## 想改什么

- **换曲子、加曲子**：改 `sing_server/melodies.py`，每首歌就是一串「音高 + 拍数」；豆包唱的话，还要在 `doubao_sing.py` 的 `TUNES` 里加一句这首歌的开头歌词。只能用过了版权期的老歌，比如童谣、民歌。
- **换嗓子**：豆包唱的话，改 `doubao_sing.py` 里的 `PERSONA` 那句人设。SoulX 唱的话，`sing_server/voice/` 里的 `prompt.wav` 是她的声音样本（6 秒左右），`prompt.json` 标的是这段话每个字的起止时间和音高。换成别的声音，这两个文件要一起换，可以用 SoulX-Singer 自带的预处理脚本生成。
- **改她什么时候唱、歌词怎么写**：改 `main.py` 里 `sing_song` 那段说明文字。大模型就是照着这段话决定什么时候唱、歌词写几个字。

## 常见问题

- **她说嗓子哑了**：豆包唱的话，是没找到豆包语音的凭证（导入时语音要选 3，或者在插件设置里填）；SoulX 唱的话，是唱歌服务没开，或者插件设置里的地址不对。
- **语音发不出来**：先在 NapCat 里确认能发普通语音。
- **唱得慢**：看唱歌服务窗口的第一行，写的是 `on cpu` 就说明没用上显卡，检查显卡驱动和第一步装的 PyTorch。
