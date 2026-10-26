#!/usr/bin/env bash
# Optional native SoulX-Singer service for Debian 13.
# Uses uv-managed Python 3.12, NEVER system pip (Trixie uses Python 3.13 / PEP 668).
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${DAFEIYU_SING_ROOT:-$HOME/dafeiyu/sing}"
MODEL="$ROOT/models/SoulX-Singer/model.pt"
MODEL_URL="${DAFEIYU_MODEL_URL:-https://hf-mirror.com/Soul-AILab/SoulX-Singer/resolve/main/model.pt}"
need() { command -v "$1" >/dev/null 2>&1 || { echo "缺少命令 $1" >&2; exit 1; }; }
for bin in git curl uv; do need "$bin"; done
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "警告：没有 nvidia-smi，SoulX 可能只能在 CPU 上运行，速度会很慢。" >&2
fi

mkdir -p "$ROOT/models/SoulX-Singer"
if [[ ! -d "$ROOT/SoulX-Singer/.git" ]]; then
  [[ ! -e "$ROOT/SoulX-Singer" ]] || { echo "源码目录已存在但不是 git 仓库：$ROOT/SoulX-Singer" >&2; exit 1; }
  git clone --depth 1 https://github.com/Soul-AILab/SoulX-Singer "$ROOT/SoulX-Singer"
fi

uv python install 3.12
if [[ ! -x "$ROOT/venv/bin/python" ]]; then
  uv venv "$ROOT/venv" --python 3.12
fi
PY="$ROOT/venv/bin/python"
"$PY" -c 'import sys; assert sys.version_info[:2] == (3, 12)' || {
  echo "虚拟环境不是 Python 3.12，请手动检查 $ROOT/venv。" >&2; exit 1;
}
uv pip install --python "$PY" torch==2.5.1 torchaudio==2.5.1 --index-url https://download.pytorch.org/whl/cu124
uv pip install --python "$PY" -r "$HERE/requirements.txt"

# The model download is resumable. Keep the large download out of the Git repository.
if [[ ! -f "$MODEL" ]] || [[ "$(stat -c %s "$MODEL")" -lt 2818092278 ]]; then
  echo "开始下载约 2.8 GB 的 SoulX 模型到 $MODEL"
  curl --fail --location --retry 3 --continue-at - --output "$MODEL" "$MODEL_URL"
fi
[[ "$(stat -c %s "$MODEL")" -ge 2818092278 ]] || {
  echo "模型文件不完整：$MODEL。可重试安装脚本续传。" >&2; exit 1;
}

for py in sing_server.py melodies.py doubao_backend.py pitch_check.py; do
  cp -f "$HERE/$py" "$ROOT/$py"
done
cp -r "$HERE/voice" "$ROOT/"
echo "安装完成。启动：bash $HERE/start_sing_server.sh"
echo "默认监听 127.0.0.1:18620；如 AstrBot 运行在 Docker，请先阅读本插件 README 的容器联网说明。"
