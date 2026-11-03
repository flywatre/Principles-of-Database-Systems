#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "=== 各 Lab 的 TODO 分布 ==="
for p in P0 P1 P2 P3 P4; do
  n=$(grep -rl "TODO($p)" src 2>/dev/null | wc -l)
  printf '  %s: %s 个文件\n' "$p" "$n"
done

echo
echo "=== P1 需要改的文件 ==="
grep -rl "TODO(P1)" src 2>/dev/null | sed 's/^/  /'

echo
echo "=== P1 相关测试文件 ==="
ls test/ | grep -E '^(lru_k|lru_|buffer_pool|disk_scheduler|page_guard)' | sed 's/^/  /'

echo
echo "=== 各测试文件里 DISABLED_ 的数量 ==="
for f in test/lru_k_replacer_test.cpp test/buffer_pool_manager_test.cpp test/disk_scheduler_test.cpp test/page_guard_test.cpp; do
  [ -f "$f" ] && printf '  %-40s %s 个\n' "$f" "$(grep -c 'DISABLED_' "$f")"
done

echo
echo "=== lru_k_replacer_test.cpp 里的测试名 ==="
grep -oE 'TEST\([A-Za-z0-9_]+, *[A-Za-z0-9_]*' test/lru_k_replacer_test.cpp | sed 's/^/  /' | head -12

echo
echo "=== docs 目录 ==="
ls docs/ 2>/dev/null | sed 's/^/  /'

echo
echo "=== 有没有 .vscode / clangd 配置 ==="
ls -a | grep -E 'vscode|clangd|clang-format' | sed 's/^/  /'
