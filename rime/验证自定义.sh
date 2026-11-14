#!/usr/bin/env bash
# 验证万象自定义配置是否生效(只读,不修改任何文件)
set -uo pipefail

RIME="$HOME/.local/share/fcitx5/rime"
BUILD="$RIME/build/wanxiang.schema.yaml"
fail=0

say() { printf '%-46s %s\n' "$1" "$2"; }
ok()  { say "$1" "✓ $2"; }
bad() { say "$1" "✗ $2"; fail=1; }

echo "===== 环境 ====="
say "fcitx5" "$(fcitx5 --version 2>/dev/null | head -1)"
say "librime" "$(cat "$RIME/version.txt" 2>/dev/null)"
say "万象版本" "$(grep -m1 'wanxiang.version *=' "$RIME/lua/wanxiang/wanxiang.lua" | sed 's/.*= *"//;s/"//')"
bt=$(grep -m1 'last_build_time' "$RIME/user.yaml" | awk '{print $2}')
say "最后部署" "$(date -d "@$bt" '+%Y-%m-%d %H:%M:%S')  (last_build_time=$bt)"

echo
echo "===== 自定义项是否写入 build ====="
cnt() { # $1=描述 $2=ERE $3=期望条数
  local n
  n=$(grep -cE "$2" "$BUILD" || true)
  if [ "$n" -eq "$3" ]; then ok "$1" "build 中命中 $n 条"; else bad "$1" "期望 $3 条,实际 $n 条"; fi
}

cnt "① 部分上屏转发 Alt+1~0 → Ctrl+1~0" 'accept: "Alt\+[0-9]", send: "Control\+[0-9]"' 10
cnt "② Ctrl+A/Ctrl+S 注释音调热键已吞掉" 'accept: "Control\+[as]", send: VoidSymbol' 2
cnt "③ 有候选时 Return 上屏当前候选" 'accept: Return, send: space' 1

QS=$(awk '/^quick_symbol_text:/{f=1} f&&/^[a-z_]+:/&&!/^quick_symbol_text:/{exit} f' "$BUILD")
if [ -n "$QS" ]; then
  ok "④ quick_symbol_text 节点存在" "已生成"
  printf '    f/ → %s   g/ → %s\n' \
    "$(printf '%s\n' "$QS" | grep -E '^    f: ' | sed 's/.*: *//')" \
    "$(printf '%s\n' "$QS" | grep -E '^    g: ' | sed 's/.*: *//')"
else
  bad "④ quick_symbol_text 节点存在" "缺失"
fi

echo
echo "===== 依赖的上游 Lua / 库锚点 ====="
anchor() { # $1=描述 $2=文件 $3=字面串
  if grep -qF "$3" "$2" 2>/dev/null; then ok "$1" "找到"; else bad "$1" "缺失: $3"; fi
}
anchor "partial_commit 只认 Ctrl+数字" "$RIME/lua/wanxiang/partial_commit.lua" 'if not key:ctrl() or key:release() then'
anchor "super_processor 读 quick_symbol_text" "$RIME/lua/wanxiang/super_processor.lua" 'config:get_map("quick_symbol_text/symkey")'
lib=$(ldconfig -p | awk '/librime.so/{print $NF; exit}')
if [ -n "$lib" ]; then
  say "librime 路径" "$lib"
  if strings "$lib" > /tmp/opencode/_librime.strings 2>/dev/null && grep -qx 'VoidSymbol' /tmp/opencode/_librime.strings; then
    ok "librime 认识 VoidSymbol 键名" "strings 命中"
  else
    bad "librime 认识 VoidSymbol 键名" "未命中"
  fi
else
  bad "librime 路径" "未找到 librime.so"
fi

echo
echo "===== 辅助文件 ====="
for f in 符号快打速查.md 练符号快打.py; do
  [ -f "$RIME/$f" ] && ok "$f" "存在" || bad "$f" "缺失"
done

echo
if [ "$fail" -eq 0 ]; then echo "全部检查通过"; else echo "有检查项未通过"; fi
exit "$fail"