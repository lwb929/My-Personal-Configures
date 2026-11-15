#!/usr/bin/env bash
# 备份 open_design_data 数据卷
#   ./backup.sh          安全模式：短暂停止容器 -> tar -> 启动（推荐，SQLite 一致）
#   ./backup.sh --live   热备份：不停容器（可能拿到不一致的 SQLite 快照，仅应急）
# 注意：用 od 镜像自身做 tar，不依赖 Docker Hub 的 alpine。
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a

IMAGE="${OPEN_DESIGN_IMAGE:-ghcr.io/nexu-io/od:0.27.1}"
NAME="open-design"
LIVE=0
[ "${1:-}" = "--live" ] && LIVE=1

mkdir -p backups
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="backups/open_design_data-${STAMP}.tgz"

was_running=0
if [ "$LIVE" -eq 0 ]; then
  if docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null | grep -q true; then
    was_running=1
    echo "[od] 暂停容器（保证 SQLite 一致性）…"
    docker stop --time 15 "$NAME" >/dev/null
  fi
fi

echo "[od] 打包数据卷 -> $OUT"
docker run --rm --user 0:0 --volumes-from "$NAME" --entrypoint sh "$IMAGE" \
  -c 'cd /app/.od && tar czf - .' > "$OUT"

if [ "$was_running" -eq 1 ]; then
  echo "[od] 恢复容器…"
  docker start "$NAME" >/dev/null
fi

SIZE="$(du -h "$OUT" | cut -f1)"
echo "[od] 完成：$OUT ($SIZE)"
echo "[od] 校验：tar tzf '$OUT' | head"
tar tzf "$OUT" | head -5
