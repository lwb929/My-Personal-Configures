#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""万象「字母 + /」符号快打 —— 肌肉记忆训练

用法:
    python3 练符号快打.py          # 看符号，敲字母
    python3 练符号快打.py -r       # 看字母，报符号
    python3 练符号快打.py -n 40    # 一轮 40 题(默认 20)

答错会插入队尾重考；中途输入 quit 或按 Ctrl+C 退出。
"""

import argparse
import random
import sys
import time

# 字母 -> 输出（与 build/wanxiang.schema.yaml 的 quick_symbol_text 保持一致）
TABLE = {
    "q": "重复上次上屏",
    "w": "？",
    "e": "（",
    "r": "）",
    "t": "Tab",
    "y": "·",
    "u": "『",
    "i": "』",
    "o": "〖",
    "p": "〗",
    "a": "！",
    "s": "……",
    "d": "、",
    "f": "•",
    "g": "‧",
    "h": "‘",
    "j": "’",
    "k": "【",
    "l": "】",
    "z": "。”",
    "x": "？”",
    "c": "！”",
    "v": "——",
    "b": "%",
    "n": "《",
    "m": "》",
}

REVERSE = {v: k for k, v in TABLE.items()}


def ask(prompt):
    try:
        return input(prompt).strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return "quit"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-r", "--reverse", action="store_true", help="反向：看字母报符号")
    ap.add_argument("-n", "--num", type=int, default=20, help="一轮题数")
    args = ap.parse_args()

    pool = list(TABLE.keys())
    queue = [random.choice(pool) for _ in range(args.num)]

    errors = {}
    times = []
    answered = 0
    wrong_total = 0
    seen = set()
    first_total = 0
    first_correct = 0

    print("\n=== 万象符号快打训练 ===")
    print("模式:" + ("字母 → 符号" if args.reverse else "符号 → 字母键"))
    print("规则: 敲字母后回车; 答错会重考; 输入 quit 退出\n")

    while queue:
        key = queue.pop(0)
        if args.reverse:
            prompt = f"[{key}/] 输出什么? > "
            expect = TABLE[key]
            hint = expect
        else:
            prompt = f"[{TABLE[key]}] 哪个键? > "
            expect = key
            hint = key

        t0 = time.time()
        ans = ask(prompt)
        dt = time.time() - t0
        if ans == "quit":
            break

        answered += 1
        times.append(dt)
        first_time = key not in seen
        if first_time:
            seen.add(key)
            first_total += 1

        ok = (ans == expect) or (not args.reverse and ans == expect + "/") \
            or (args.reverse and ans.strip() == expect)

        if ok:
            if first_time:
                first_correct += 1
            print(f"   ✓  {key}/ → {TABLE[key]}")
        else:
            wrong_total += 1
            errors[key] = errors.get(key, 0) + 1
            print(f"   ✗  应为 “{hint}”（{key}/ → {TABLE[key]}），已排到队尾重考")
            queue.append(key)
            if args.reverse:
                queue.append(key)  # 反向模式多练一次

        if len(errors) and wrong_total and wrong_total % 5 == 0:
            print(f"   —— 已答 {answered}，错误 {wrong_total} ——")

    print("\n=== 本轮结束 ===")
    print(f"做题数: {answered}　总错误: {wrong_total}")
    if answered:
        print(f"首答正确率: {first_correct / max(first_total, 1) * 100:.0f}%")
        print(f"平均反应: {sum(times) / len(times):.2f}s")
    if errors:
        print("最常错: " + "　".join(
            f"{k}/（{TABLE[k]}）x{v}" for k, v in sorted(errors.items(), key=lambda x: -x[1])
        ))
    else:
        print("全对，可以加题量到 -n 40 了")
    print("复习卡: ~/.local/share/fcitx5/rime/符号快打速查.md")


if __name__ == "__main__":
    main()
