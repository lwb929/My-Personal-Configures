#!/usr/bin/env bash
# dotfiles 安装脚本：将本仓库配置软链回真实位置
# 已存在的目标文件会先备份为 <name>.bak.$(date +%Y%m%d%H%M%S)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

link() { # link <src> <dst>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "$dst.bak.$TS"
    echo "backup: $dst -> $dst.bak.$TS"
  fi
  ln -sfn "$src" "$dst"
  echo "link:   $dst -> $src"
}

# nvim (LazyVim)
link "$REPO_DIR/nvim" "$HOME/.config/nvim"

# zsh
link "$REPO_DIR/zsh/zshrc"  "$HOME/.zshrc"
link "$REPO_DIR/zsh/zshenv" "$HOME/.zshenv"

# rime：逐个软链仓库内文件到 fcitx5 rime 目录（不覆盖 userdb/build/sync 等本地数据）
RIME_DIR="$HOME/.local/share/fcitx5/rime"
mkdir -p "$RIME_DIR"
find "$REPO_DIR/rime" -mindepth 1 -maxdepth 1 | while read -r item; do
  link "$item" "$RIME_DIR/$(basename "$item")"
done

echo "完成。重启 fcitx5 并执行 rime 重新部署即可生效。"
