#!/usr/bin/env bash
# 从备份恢复数据卷（会覆盖当前数据！执行前要求二次确认）
#   ./restore.sh backups/open_design_data-20261115-120000.tgz
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a

IMAGE="${OPEN_DESIGN_IMAGE:-ghcr.io/nexu-io/od:0.27.1}"
NAME="open-design"
ARCHIVE="${1:?用法: ./restore.sh backups/xxx.tgz}"
[ -f "$ARCHIVE" ] || { echo "文件不存在: $ARCHIVE" >&2; exit 1; }

echo "即将用 $ARCHIVE 覆盖数据卷 open_design_data。"
read -r -p "确认？输入 RESTORE 继续: " ans
[ "$ans" = "RESTORE" ] || { echo "已取消"; exit 1; }

echo "[od] 停止容器…"
docker compose stop || true

echo "[od] 解包到数据卷…"
docker run --rm -i --user 0:0 --volumes-from "$NAME" --entrypoint sh "$IMAGE" \
  -c 'rm -rf /app/.od/* && tar xzf - -C /app/.od && chown -R 1001:1001 /app/.od' < "$ARCHIVE"

echo "[od] 启动容器…"
docker compose up -d
docker compose ps
