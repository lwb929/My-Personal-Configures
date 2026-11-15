# OpenDesign 服务端部署包

单容器跑 OpenDesign：一个 node 进程同时提供 Web UI（静态导出）、`/api/*`、SQLite 存储。
**只从 `ghcr.io` 拉镜像**，不依赖 Docker Hub。

## 文件

| 文件 | 作用 |
|---|---|
| `docker-compose.yml` | 服务定义（端口、卷、资源、健康检查） |
| `.env.example` | 配置模板；`install.sh` 会复制成 `.env` 并生成 token |
| `install.sh` | 幂等部署：建 `.env` → 校验 → pull → up → 等健康 |
| `verify.sh` | 接口自检（鉴权、内置资产计数、首页、卷、资源） |
| `backup.sh` / `restore.sh` | 数据卷备份/恢复（用 od 镜像自身 tar，无 Hub 依赖） |
| `Caddyfile` / `nginx.conf.example` | 反代示例（宿主原生安装时用） |

## 1. 前置

```bash
docker --version && docker compose version
```

需要能访问 Docker daemon。若报 `permission denied ... docker.sock`：

```bash
sudo usermod -aG docker "$USER" && newgrp docker    # 或直接用 sudo 跑脚本
```

## 2. 部署

```bash
cd ~/WORKPLACE/open-design-deploy
chmod +x *.sh
./install.sh
```

`install.sh` 做的事：`.env` 不存在就建、`OD_API_TOKEN` 为空就 `openssl rand -hex 32` 生成、
`docker compose pull` + `up -d`、等 `healthy`、打印地址与密码。**不会删除任何已有容器或数据卷。**

想接模型（BYOK）再编辑 `.env`：

```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
DEEPSEEK_API_KEY=sk-...
# 或界面里填任意 OpenAI 兼容端点（Ollama / LM Studio / vLLM / Azure / Gemini）
```

改完 `docker compose up -d` 生效。

## 3. 验证

```bash
./verify.sh
```

预期：`/api/health` 200；无 token 访问 `/api/*` 返回 401；`/api/skills` 等能返回内置资产数量；
`docker stats` 空闲内存约 20–60 MiB。

浏览器打开 `http://127.0.0.1:7456`，用户名 `open-design`，密码为 `.env` 里的 `OD_API_TOKEN`。

## 4. 远程访问（服务器场景）

**首选 SSH 隧道**，不额外开端口：

```bash
ssh -L 7456:127.0.0.1:7456 user@server
# 本地浏览器开 http://127.0.0.1:7456
```

需要域名直连时，用**宿主上的** Caddy/Nginx 反代（不要用 caddy 容器，本机拉不到 Docker Hub）：

```bash
sudo caddy run --config Caddyfile      # 详见 Caddyfile 注释
```

同时必须配白名单，否则 `/api` 会被 Origin 校验拒掉：

```bash
# .env
OPEN_DESIGN_ALLOWED_ORIGINS=https://od.example.com
OPEN_DESIGN_BIND=127.0.0.1
```

> 安全边界：`OD_API_TOKEN` 是**单租户共享密钥**，不是多用户账号体系。公网暴露必须加 TLS，
> 且不要设置 `OPEN_DESIGN_DISABLE_API_AUTH=1` 除非反代已强制认证。

## 5. 备份与恢复

```bash
./backup.sh                 # 停容器→tar→起容器，SQLite 一致（推荐，停机约 2-5s）
./backup.sh --live          # 热备，不停机，快照可能不一致（应急用）
./restore.sh backups/open_design_data-YYYYmmdd-HHMMSS.tgz
```

数据全在命名卷 `open_design_data`（容器内 `/app/.od`）。**删卷 = 删全部项目/会话/设置。**

## 6. 升级与回滚

```bash
# 升级：改 .env 里的 OPEN_DESIGN_IMAGE（如 0.27.1 -> 下一版），然后
docker compose pull && docker compose up -d --no-build
./verify.sh

# 回滚：改回旧 tag，再 pull + up
```

数据卷跨版本保留；官方说明若从早期（容器以 uid 1000 运行）升级过来，可能需要：

```bash
docker run --rm --user 0:0 -v open_design_data:/d --entrypoint sh ghcr.io/nexu-io/od:0.27.1 \
  -c 'chown -R 1001:1001 /d'
```

## 7. 排障

| 现象 | 原因 / 处理 |
|---|---|
| `permission denied /var/run/docker.sock` | 用户不在 `docker` 组 → `sudo usermod -aG docker $USER` 后重登 |
| 容器 `unhealthy` | `docker compose logs --tail=100`；多为内存不足 → 调 `OPEN_DESIGN_MEM_LIMIT`/`NODE_OPTIONS` |
| 浏览器一直弹登录框 | 容器内 `OD_BIND_HOST=0.0.0.0` 使对端非 loopback，属正常；输入 `open-design` + token |
| 页面能开但生成报错 | 没配模型 key。BYOK 或挂 CLI（见下） |
| 反代后 `/api` 401/403 | 没配 `OPEN_DESIGN_ALLOWED_ORIGINS`（写精确 origin，含协议和端口） |
| 导出/大会话 OOM | 提高 `OPEN_DESIGN_MEM_LIMIT=2g`、`NODE_OPTIONS=--max-old-space-size=1024` |
| 拉镜像慢/失败 | 只走 ghcr；确认 `curl -I https://ghcr.io/v2/` 可达，必要时给 dockerd 配代理 |

## 8. Docker 版的已知限制

- **镜像不含任何 agent CLI**（无 claude/codex/cursor-agent）→ 只能 BYOK 或 OpenDesign Cloud。
  Linux 想用本机已有 CLI：官方 `deploy/docker-compose.linux.yml` + `Dockerfile.local`（挂载 + host 网络）。
- **无 chromium / ffmpeg**（运行阶段只有 `tini poppler-utils bash git`）→ HyperFrames 视频渲染、
  依赖无头浏览器的导出不可用；PPTX 属 agent-driven，纯 BYOK 基本不可用。
- **MCP 用不上**：`od mcp install` 是 stdio，宿主 agent 无法直接连容器内的 MCP；要 MCP 请跑源码/AppImage。
- **单租户**：一个共享 token，无用户隔离；多人协作需各自隧道或反代上加认证。
- 容器 `read_only: true`，可写位置仅 `/app/.od`（卷）与 `/tmp`（tmpfs 512m）。
