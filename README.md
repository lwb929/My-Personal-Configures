# dotfiles

个人开源配置：Neovim (LazyVim)、Rime 输入法（万象方案）、zsh。
发布于独立的 GitHub 账号，与本机日常 git 身份通过 `includeIf` 分离。

## 目录结构

```
nvim/    Neovim 配置（LazyVim 发行版 + 自定义 plugins）
rime/    fcitx5-rime 万象拼音方案（schema / dict / lua / opencc）
zsh/     zshrc / zshenv（oh-my-zsh + eza + 代理开关函数）
install.sh  一键软链安装（自动备份已有文件）
```

## 安装

```bash
git clone https://github.com/<你的开源账号>/dotfiles.git
cd dotfiles
./install.sh
```

## 各部分说明

### nvim
基于 [LazyVim](https://www.lazyvim.org/)。`lua/plugins/` 为自定义插件配置，`lazy-lock.json` 锁定插件版本，保证可复现。

### rime
基于 [万象拼音](https://github.com/amzxyz/rime_wanxiang) 方案。使用前建议先 clone 上游仓库获取 `rime-wanxiang-base` 等基础资源（本仓库不含，见「脱敏清单」）：

```bash
git clone https://github.com/amzxyz/Rime-Wanxiang.git ~/.local/share/fcitx5/rime/rime-wanxiang-base
```

之后重启 fcitx5 并重新部署。

### zsh
oh-my-zsh + 插件：zsh-autosuggestions / zsh-syntax-highlighting / z / extract。内置 `proxy_on` / `proxy_off` 代理开关。

## 脱敏清单（私有数据，不入库）

| 排除项 | 原因 |
|---|---|
| `*.userdb/`（en / luna_pinyin / sequence / stats / wanxiang） | 打字历史与用户词频，含大量个人信息 |
| `sync/` | rime 同步数据，含用户词库 |
| `installation.yaml` | 含 installation_id（设备 UUID） |
| `user.yaml`、`stats.userdb` | 本机运行状态 |
| `build/` | 编译产物 |
| `rime-wanxiang-base/` | 上游项目内容，应从官方仓库获取 |

## git 身份分离

| `agent/` 整个目录 | LLM provider 模型配置，按用户要求完全不开源 |

本仓库使用与日常不同的 GitHub 账号，通过 git `includeIf` 实现：

- `~/.gitconfig`：全局身份 + 追加 `gitdir:~/WORKPLACE/dotfiles/` 指向 `~/.gitconfig-work`
- `~/.gitconfig-work`：开源账号的 `user.name` / `user.email`

验证：`git -C ~/WORKPLACE/dotfiles config user.name` 应显示开源账号名，而全局 `git config --global user.name` 不变。推送时为该账号配置对应的 SSH deploy key 或 PAT。

## 隐私威胁模型说明

发布公开仓库前按「社会工程学侦查聚合」视角审查过，已清除的泄露面：

| 类别 | 泄露项 | 处理 |
|---|---|---|
| 身份关联链 | 自建网关域名（含真实 ID） | 替换为 `gateway.example.com` |
| 基础设施拓扑 | 局域网固定 IP + 自建服务端口 | 替换为 TEST-NET 地址 `192.0.2.10` |
| 设备指纹 | `installation.yaml`（设备 UUID）、`*.userdb`（打字历史可重建个人画像） | 不入库 |
| 凭证 | opencode 配置、`auth.json`（真实 API key） | 不入库（模型配置已按决定完全移除） |

仍保留的已知暴露面（有意保留，推送前知悉即可）：

- `zsh/zshrc` 中 `proxy_on` 的端口 `10808` / `12345`：常见代理工具默认端口，能推断本机使用代理工具。如介意可改为任意高位端口。
- git 提交的**时间戳和时区**会暴露活跃时段（东八区）。如介意，推送前可用 `git filter-repo` 或延后分批提交。
- rime 词库含上游作者公开署名（`skoj@qq.com`），属上游项目自带内容。

## LICENSE

MIT
