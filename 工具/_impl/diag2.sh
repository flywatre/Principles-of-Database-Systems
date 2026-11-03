#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "=== run_clang_tidy.py 第一行（用 cat -A 显示不可见字符）==="
head -1 build_support/run_clang_tidy.py | cat -A | sed 's/^/  /'
echo "=== cpplint.py 第一行 ==="
head -1 build_support/cpplint.py | cat -A | sed 's/^/  /'
echo "=== run_clang_format.py 第一行 ==="
head -1 build_support/run_clang_format.py | cat -A | sed 's/^/  /'

echo
echo "=== 各脚本 CR 行数 ==="
for f in build_support/cpplint.py build_support/run_clang_tidy.py build_support/run_clang_format.py; do
  printf '  %-40s %s\n' "$f" "$(grep -c $'\r' "$f")"
done

echo
echo "=== 日志里的真实报错 ==="
for l in /tmp/fmt2.log /tmp/lint2.log /tmp/tidy2.log; do
  echo "--- $l ---"
  head -8 "$l" | sed 's/^/  /'
done
