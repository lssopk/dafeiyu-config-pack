#!/usr/bin/env bash
# Debian 13 / Linux entry point for the existing cross-platform Python importer.
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ ! -f tools/import_dafeiyu.py || ! -f settings/pack.json ]]; then
  echo "错误：请先完整克隆/解压仓库，不能单独下载这个脚本。" >&2
  exit 1
fi

PY=""
if [[ -n "${DAFEIYU_PYTHON:-}" ]]; then
  PY="$DAFEIYU_PYTHON"
elif [[ -x "$HOME/.astrbot_launcher/venv/bin/python" ]]; then
  PY="$HOME/.astrbot_launcher/venv/bin/python"
else
  shopt -s nullglob
  for candidate in "$HOME"/.astrbot_launcher/instances/*/venv/bin/python; do
    if [[ -x "$candidate" ]]; then PY="$candidate"; break; fi
  done
  shopt -u nullglob
fi

if [[ -z "$PY" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    PY="$(command -v python3)"
  else
    echo "缺少 Python 3。Debian 13 可运行：sudo apt install python3" >&2
    exit 1
  fi
fi

if ! "$PY" -c 'import sys; assert sys.version_info >= (3, 9)' 2>/dev/null; then
  echo "需要 Python 3.9 或更高版本，当前候选：$PY" >&2
  exit 1
fi

echo "运行环境：$("$PY" --version 2>&1) ($PY)"
echo "提示：AstrBot、NapCat 和 QQ 对话模型需先完成配置。"
echo "提示：SSH 中运行该脚本即可，无需 GNOME 桌面终端。"
exec "$PY" -X utf8 "$ROOT/tools/import_dafeiyu.py" "$@"
