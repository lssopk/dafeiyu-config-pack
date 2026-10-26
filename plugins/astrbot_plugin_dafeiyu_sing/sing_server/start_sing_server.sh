#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="${DAFEIYU_SING_ROOT:-$HOME/dafeiyu/sing}"
PY="$ROOT/venv/bin/python"
[[ -x "$PY" ]] || { echo "未安装：先执行 bash setup_linux.sh" >&2; exit 1; }
[[ -f "$ROOT/models/SoulX-Singer/model.pt" ]] || { echo "缺少 SoulX 模型" >&2; exit 1; }
exec "$PY" "$ROOT/sing_server.py" \
  --soulx "$ROOT/SoulX-Singer" \
  --model "$ROOT/models/SoulX-Singer/model.pt" \
  --voice "$ROOT/voice" \
  --host "${SING_HOST:-127.0.0.1}" \
  --port "${SING_PORT:-18620}" "$@"
