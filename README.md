# My Personal Configures

个人配置与部署脚本索引。

| 目录 | 内容 | 说明 |
|---|---|---|
| [`deploy/open-design/`](deploy/open-design/) | OpenDesign 服务端部署包（Docker Compose） | 单容器：Web UI + `/api` + SQLite；含备份/恢复/反代/自检脚本 |
| [`nvim/`](nvim/) | Neovim 配置（LazyVim + 自定义插件） | `lazy-lock.json` 锁版本，可复现 |
| [`rime/`](rime/) | fcitx5-rime 万象拼音方案 | schema / dict / lua / custom；userdb 打字历史不入库 |
| [`zsh/`](zsh/) | zshrc / zshenv | oh-my-zsh + eza + 代理开关函数 |
| [`install.sh`](install.sh) | 配置软链安装脚本 | 自动备份已有文件 |

## dotfiles 使用

```bash
git clone https://github.com/lwb929/My-Personal-Configures.git
cd My-Personal-Configures
./install.sh
```

### rime 前置

基于 [万象拼音](https://github.com/amzxyz/rime_wanxiang)，需先获取上游基础资源：

```bash
git clone https://github.com/amzxyz/Rime-Wanxiang.git ~/.local/share/fcitx5/rime/rime-wanxiang-base
```

之后重启 fcitx5 并重新部署。

## 隐私威胁模型说明

发布公开仓库前按「社会工程学侦查聚合」视角审查过，已清除的泄露面：

| 类别 | 泄露项 | 处理 |
|---|---|---|
| 身份关联链 | 自建网关域名（含真实 ID） | 已从仓库移除 |
| 基础设施拓扑 | 局域网固定 IP + 自建服务端口 | 已从仓库移除 |
| 设备指纹 | `installation.yaml`（设备 UUID）、`*.userdb`（打字历史可重建个人画像） | 不入库 |
| 凭证 | opencode 配置、`auth.json`（真实 API key） | 不入库（模型配置完全不开源） |

仍保留的已知暴露面（有意保留）：

- `zsh/zshrc` 中 `proxy_on` 的端口 `10808` / `12345`：常见代理工具默认端口，能推断本机使用代理工具。
- git 提交的**时间戳和时区**会暴露活跃时段（东八区）。
- rime 词库含上游作者公开署名（`skoj@qq.com`），属上游项目自带内容。

## 约定

- 所有含密钥的文件（`.env`、`*.tgz`、`backups/`）由各目录内 `.gitignore` 排除，**不入库**。
- 部署类目录必须自带 `README.md`，写明前置条件、验证方式、回滚方式。

## LICENSE

MIT
