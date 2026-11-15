#!/usr/bin/env bash
# OpenDesign 幂等部署脚本
# - 不删除任何已有容器/卷/数据
# - .env 不存在才创建；OD_API_TOKEN 为空才生成
# - 只从 ghcr.io 拉镜像（本机 Docker Hub 不可达）
set -euo pipefail
cd "$(dirname "$0")"

log() { printf '\033[1;36m[od]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[od] %s\033[0m\n' "$*" >&2; exit 1; }

# ---------- 0. 前置检查 ----------
command -v docker >/dev/null || die "未安装 docker"
docker compose version >/dev/null 2>&1 || die "缺少 docker compose 插件"

if ! docker info >/dev/null 2>&1; then
  cat >&2 <<'EOF'
[od] 当前用户无权访问 Docker daemon（/var/run/docker.sock 属 root:docker）。
     二选一：
       A) sudo usermod -aG docker "$USER" && newgrp docker      # 之后免 sudo
       B) sudo ./install.sh                                      # 本次直接用 sudo 跑
EOF
  exit 1
fi

# ---------- 1. 准备 .env ----------
if [ ! -f .env ]; then
  cp .env.example .env
  chmod 600 .env
  log "已从 .env.example 生成 .env"
fi

if grep -qE '^OD_API_TOKEN=\s*$' .env; then
  token="$(openssl rand -hex 32)"
  # 用 | 作分隔符，避免 token 中的特殊字符影响替换
  sed -i "s|^OD_API_TOKEN=.*|OD_API_TOKEN=${token}|" .env
  log "已生成随机 OD_API_TOKEN 并写入 .env"
fi

set -a; . ./.env; set +a
[ -n "${OD_API_TOKEN:-}" ] || die ".env 中 OD_API_TOKEN 为空"

PORT="${OPEN_DESIGN_PORT:-7456}"
BIND="${OPEN_DESIGN_BIND:-127.0.0.1}"

# ---------- 2. 校验 compose ----------
docker compose config -q || die "docker-compose.yml 解析失败"
log "compose 配置校验通过（镜像 ${OPEN_DESIGN_IMAGE:-ghcr.io/nexu-io/od:0.27.1}）"

# ---------- 3. 拉取并启动（不 --force-recreate，不碰数据卷）----------
log "拉取镜像…"
docker compose pull

log "启动…"
docker compose up -d

# ---------- 4. 等健康检查 ----------
log "等待健康检查（最多 90s）…"
for i in $(seq 1 45); do
  state="$(docker inspect -f '{{.State.Health.Status}}' open-design 2>/dev/null || echo starting)"
  if [ "$state" = "healthy" ]; then
    log "容器 healthy ✅"
    break
  fi
  if [ "$i" -eq 45 ]; then
    docker compose ps
    docker compose logs --tail=40
    die "健康检查未通过，见上方日志"
  fi
  sleep 2
done

# ---------- 5. 接口自检 ----------
code="$(curl -s -o /dev/null -w '%{http_code}' "http://${BIND}:${PORT}/api/health" || true)"
log "GET /api/health -> ${code}（未鉴权时为 401 属正常）"

cat <<EOF

部署完成。

  访问地址 : http://${BIND}:${PORT}
  浏览器登录: 用户名 open-design  /  密码 $(grep '^OD_API_TOKEN=' .env | cut -d= -f2)
             （或用 curl -H "Authorization: Bearer <token>"）

  远程机器请走隧道，不要直接对公网开端口：
    ssh -L ${PORT}:127.0.0.1:${PORT} <user>@<server>

  常用命令:
    ./verify.sh           # 接口自检
    ./backup.sh           # 备份数据卷到 ./backups/
    docker compose logs -f --tail=100
    docker compose restart
EOF
