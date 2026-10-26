#!/usr/bin/env bash
# Debian 13 GNOME / SSH - prepare a dedicated Compose project.
# Does NOT install Docker, alter SSH/firewall/GNOME, or touch existing containers.
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"
umask 077

die() { echo "错误：$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }

[[ "${1:---up}" == "--up" || "${1:---up}" == "--check" ]] || die "用法：bash bootstrap.sh [--check|--up]"
command -v docker >/dev/null 2>&1 || die "未安装 Docker。Debian 13 可先安装 docker.io docker-compose。"
docker info >/dev/null 2>&1 || die "当前账户不能访问 Docker daemon；请使用有权限的账户执行（例如 sudo bash bootstrap.sh）。"
docker compose version >/dev/null 2>&1 || die "缺少 Docker Compose v2：请安装 Debian 的 docker-compose 包。"
command -v python3 >/dev/null 2>&1 || die "需要 python3 来生成随机 NapCat 管理 token。"

# For the first install, fail closed on occupied host ports.
if [[ ! -f .env ]]; then
  for port in 6185 6099; do
    if command -v ss >/dev/null 2>&1 && ss -H -ltn "( sport = :$port )" | grep -q .; then
      die "检测到端口 $port 已在监听。可能已有服务；不要覆盖。先检查：ss -ltnp | grep :$port"
    fi
  done
fi

# Validate the Compose template without requiring a preexisting secret.
NAPCAT_WEBUI_TOKEN=temporary-validation-only docker compose config --quiet || die "Compose 配置无效。"
if [[ "${1:---up}" == "--check" ]]; then
  info "环境检查通过。仅检查，没有创建文件或启动容器。"
  exit 0
fi

if [[ ! -e .env ]]; then
  token="$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')"
  uid="${NAPCAT_UID:-${SUDO_UID:-$(id -u)}}"
  gid="${NAPCAT_GID:-${SUDO_GID:-$(id -g)}}"
  if [[ "$uid" == "0" && -z "${NAPCAT_UID:-}" ]]; then uid=1000; fi
  if [[ "$gid" == "0" && -z "${NAPCAT_GID:-}" ]]; then gid=1000; fi
  [[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]] || die "NAPCAT_UID/GID 必须是数字。"
  printf 'NAPCAT_WEBUI_TOKEN=%s\nNAPCAT_UID=%s\nNAPCAT_GID=%s\nTZ=Asia/Shanghai\n' "$token" "$uid" "$gid" > .env
  chmod 600 .env
  info "已生成 .env（600 权限），包含随机 NapCat WebUI Token；请妥善保管。"
else
  info "沿用现有 .env，不重新生成 token。"
fi

# Create only missing directories; never chown existing user files.
. ./.env
for dir in data napcat/config ntqq; do
  if [[ ! -e "$dir" ]]; then
    mkdir -p "$dir"
    if [[ "$(id -u)" == 0 ]]; then
      chown "$NAPCAT_UID:$NAPCAT_GID" "$dir"
    fi
  fi
done

docker compose up -d
info "已提交启动请求。检查：docker compose ps"
info "本机浏览器：http://127.0.0.1:6185 和 http://127.0.0.1:6099/webui"
info "远程访问请使用 SSH 端口转发；不要把管理端口直接暴露到公网。"
