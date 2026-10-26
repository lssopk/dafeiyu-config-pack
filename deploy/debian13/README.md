# Debian 13 (Trixie) + GNOME / SSH 部署

此配置包适用于 **Debian 13 的 GNOME 桌面**，也可通过 SSH 在同一台 Debian 机器上执行。
GNOME 只负责提供桌面界面；AstrBot/NapCat 不依赖 GNOME 终端或桌面版 SSH 客户端。

本仓库提供两种模式：

- **已经部署了 AstrBot + NapCat**：不重复安装，直接使用仓库根目录的 `导入大肥鱼.sh`。
- **从零安装**：使用本目录的 Docker Compose 部署一套独立 AstrBot + NapCat，再导入配置。

> 注意：脚本不会连接你的服务器执行操作。必须在目标 Debian 主机上手动运行。
> 不会主动修改 SSH、GNOME、系统语言、防火墙、已有 Docker 容器或第三方服务。

## 0. 检查系统（只读）

在 Debian 桌面终端或 SSH 中运行：

    cat /etc/os-release
    uname -m
    id
    command -v docker && docker compose version || true
    sudo ss -ltnp | grep -E ':(6185|6099|6199)\b' || true

以下示例默认宿主机空闲 6185 (AstrBot WebUI) 和 6099 (NapCat WebUI)。
如果已经有 AstrBot/NapCat 或端口冲突，**不要运行新的 Docker Compose**，
直接进入第 3 节连接已有服务。

## 1. 安装基础依赖（只有未安装才需要）

Debian 13 官方软件源提供 Docker 与 Compose v2：

    sudo apt update
    sudo apt install -y git python3 docker.io docker-compose

如果 Docker 已从 Docker 官方仓库安装，跳过上面的 Docker 安装命令，避免混用不同来源的软件包。
检查：

    sudo docker info
    sudo docker compose version

通过 Docker 使用 SSH 远程管理时，**不需要开放 6185/6099 到公网**。
运行用户没有 Docker 权限时，下面启动命令使用 `sudo`；不要为了方便随便开放 Docker socket。
Docker 权限近似 root 权限。

## 2. 从零部署 AstrBot + NapCat

在 Debian 13 执行：

    git clone https://github.com/lssopk/dafeiyu-config-pack.git
    cd dafeiyu-config-pack
    sudo bash deploy/debian13/bootstrap.sh --check
    sudo bash deploy/debian13/bootstrap.sh --up

`--check` 只检测 Docker、Compose、端口和配置文件，不启动容器。
`--up` 在 `deploy/debian13/` 下生成权限为 600 的 `.env`，
为 NapCat 创建随机高强度 WebUI Token，然后启动两个容器。
重复执行会沿用原 Token 和数据，不会强制重置 QQ 登录。

日志和状态：

    cd deploy/debian13
    sudo docker compose ps
    sudo docker compose logs -f astrbot
    sudo docker compose logs -f napcat

AstrBot 的**初始密码为日志中打印的随机密码**，用户名通常是 `astrbot`。
首次登录后立即修改密码，并在后台安全设置里启用 TOTP（如果可用）。
NapCat 管理令牌位于本地 `.env` 的 `NAPCAT_WEBUI_TOKEN` 字段，不要上传或公开。
NapCat 先使用 WebUI 扫码登录 QQ 小号。此 Compose 使用 NapCat 官方的
`MODE=astrbot` 与共享数据卷，供 AstrBot 的 QQ OneBot v11 接入使用。
在 AstrBot WebUI 配置模型提供商（例如 DeepSeek）并确认 QQ 已能回复，再导入配置包。

### 浏览器访问

同一台 Debian GNOME 上的 Firefox/Chromium：

- AstrBot：http://127.0.0.1:6185
- NapCat：http://127.0.0.1:6099/webui

如果是从你自己的 Windows 电脑通过 SSH 管理远程 Debian：

    ssh -N -L 6185:127.0.0.1:6185 -L 6099:127.0.0.1:6099 用户名@服务器IP

保持 SSH 连接，在 Windows 浏览器中打开上述两个 localhost 地址。
如果 Windows 本地端口已被其他程序占用，可将左侧端口换成其他数字：
`-L 16185:127.0.0.1:6185`，浏览器访问 `http://127.0.0.1:16185`。

默认只绑定宿主机回环地址，不向互联网开放管理端口。
**若调整端口或防火墙，请先确认现有服务情况**，尤其不要盲目清理 Docker 数据卷。

## 3. 导入大肥鱼（新部署或已有 AstrBot 都适用）

在仓库**根目录**执行（SSH 或 GNOME 终端都可以）：

    sudo apt install -y python3
    bash ./导入大肥鱼.sh

也可以无交互运行：

    bash ./导入大肥鱼.sh --answers 回答.json

本脚本自动选择 Linux 下 AstrBot 启动器虚拟环境（如果有），否则使用系统
`python3`；没有额外 Python 第三方依赖，不需要 `sudo pip install`，
也不需要在 Debian 13 受 PEP 668 管理的系统 Python 上安装包。

脚本会提示填写：
后台地址（本机 Docker 默认 `http://127.0.0.1:6185`）、账号、密码、
主人 QQ 号、记忆方式和语音方式。

- 第一次推荐 **记忆选 0 或 2**：0 不开；2 使用硅基流动，需要自己的密钥。
- 语音选 **0（不开）或 1（Edge）** 不需要付费云语音凭证；3 是豆包，需 APP ID 与 Access Token，按用量收费。
- 选 3 的豆包语音可直接使用随包安装的**云端唱歌插件**，不需要单独搭建唱歌服务器。
- 记忆选 1 为本机 Ollama：**Docker 里 127.0.0.1 指向 AstrBot 容器，而不是宿主机**。必须自行配置容器可访问的 Ollama URL，不能直接使用默认 `127.0.0.1:11434`；否则请先选 0/2。
- Edge 语音如果报告 ffmpeg 缺失，ffmpeg 需要安装在**运行 AstrBot 的环境**里，Docker 下只在 Debian 主机安装 ffmpeg 并不能解决容器内缺失的问题。

`回答.json` 可参考根目录 README 的格式，在 Linux 路径例如
`/home/你的用户/dafeiyu-secrets.txt`。敏感文件权限应设置为 600：

    chmod 600 回答.json
    chmod 600 /home/你的用户/dafeiyu-secrets.txt

如果 AstrBot 不在本机，设置后台地址为该服务器的本机 SSH 隧道；
例如在导入端通过 `ssh -L 6185:127.0.0.1:6185` 转发后访问本地 `6185`。
请勿直接将账号密码通过明文 HTTP 发送到公网。

## 4. 可选：Linux 本地 SoulX-Singer

默认 `sing.backend=doubao` 是云端唱歌，无需额外部署。
想改为 `soulx`，需要 NVIDIA 显卡及可用的 Linux 驱动，并另行安装大型模型。
项目为 Linux 增加 `setup_linux.sh` 和 `start_sing_server.sh`，使用独立的 Python 3.12 虚拟环境，
不改动 Debian 13 系统 Python。详见 `plugins/astrbot_plugin_dafeiyu_sing/README.md`。

SoulX 服务默认监听本地 127.0.0.1:18620；
如果 AstrBot 在 Docker 中，容器无法用它自己的 localhost 访问宿主机服务，
需要配置 `host.docker.internal` 和宿主机可达的服务地址。
为了避免暴露无鉴权接口，**不要把 18620 直接放行到公网**。

## 5. 维护 / 排障

- 查看状态：`cd deploy/debian13 && sudo docker compose ps`
- 读取日志：`sudo docker compose logs --tail=100 astrbot napcat`
- 更新镜像：`sudo docker compose pull && sudo docker compose up -d`
- 停止：`sudo docker compose down`（不附加 `-v`，数据目录不会删除）
- 数据：`deploy/debian13/data`、`deploy/debian13/napcat/config` 和 `deploy/debian13/ntqq`
- 重新导入人格、设置和插件：`bash ./导入大肥鱼.sh`

> Docker Compose 部署脚本只负责运行时环境，导入配置前请先确保
> AstrBot API 与项目的目标版本兼容。仓库未在你的实际 Debian 主机上执行集成测试。

上游参考：[AstrBot Docker 文档](https://docs.astrbot.app/deploy/astrbot/docker.html)、
[NapCat Docker 官方 Compose](https://github.com/NapNeko/NapCat-Docker/blob/main/compose/astrbot.yml)。
