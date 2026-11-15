#!/usr/bin/env bash
# 接口自检：健康、鉴权、内置资产（skills / design-systems / plugins）
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env; set +a

PORT="${OPEN_DESIGN_PORT:-7456}"
BIND="${OPEN_DESIGN_BIND:-127.0.0.1}"
BASE="http://${BIND}:${PORT}"
TOKEN="${OD_API_TOKEN:?missing OD_API_TOKEN in .env}"

hr() { printf '%s\n' "------------------------------------------------------------"; }

jqcount() {
  # 不依赖 jq：用 node 统计 JSON 数组长度（镜像内/宿主都可能有 node，没有则退回字符串统计）
  python3 - "$@" 2>/dev/null <<'PY' || cat
import sys, json
raw = sys.stdin.read()
try:
    d = json.loads(raw)
except Exception:
    print("N/A (非 JSON 响应)")
    raise SystemExit(0)
if isinstance(d, dict):
    for k in ("skills", "items", "data", "plugins", "designSystems", "templates"):
        if isinstance(d.get(k), list):
            d = d[k]; break
print(len(d) if isinstance(d, list) else "N/A")
PY
}

hr; echo "1) 容器状态"
docker compose ps

hr; echo "2) /api/health（无鉴权，预期 200）"
curl -sS -o /dev/null -w "   HTTP %{http_code}\n" "$BASE/api/health"

hr; echo "3) /api/health（Bearer，预期 200）"
curl -sS -o /dev/null -w "   HTTP %{http_code}\n" -H "Authorization: Bearer $TOKEN" "$BASE/api/health"

hr; echo "4) /api/* 无 token（预期 401，说明鉴权生效）"
curl -sS -o /dev/null -w "   HTTP %{http_code}\n" "$BASE/api/skills"

hr; echo "5) 内置资产计数（带 token）"
for ep in skills design-templates plugins design-systems; do
  n="$(curl -sS -H "Authorization: Bearer $TOKEN" "$BASE/api/$ep" | jqcount)"
  printf '   %-18s %s\n' "/api/$ep" "$n"
done

hr; echo "6) 首页可访问（预期 200 且含 HTML）"
curl -sS -o /tmp/od-index.html -w "   HTTP %{http_code}  bytes=%{size_download}\n" "$BASE/" || true
grep -qi '<!doctype html' /tmp/od-index.html && echo "   首页返回 HTML ✅" || echo "   首页不是 HTML ⚠️"

hr; echo "7) 数据卷"
docker volume inspect open_design_data --format '   {{.Name}}  {{.Mountpoint}}  driver={{.Driver}}'

hr; echo "8) 资源占用"
docker stats --no-stream --format '   {{.Name}}  CPU={{.CPUPerc}}  MEM={{.MemUsage}}  PIDS={{.PIDs}}' open-design

hr; echo "完成。"
