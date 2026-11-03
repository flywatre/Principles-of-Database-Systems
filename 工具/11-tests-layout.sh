#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "=== test 目录结构（两层）==="
find test -maxdepth 2 -name '*.cpp' | sort | sed 's/^/  /'

echo
echo "=== P1 相关测试 & DISABLED_ 数量 ==="
for f in $(find test -name '*.cpp' | grep -Ei 'lru|buffer_pool|disk_sched|page_guard'); do
  printf '  %-46s DISABLED_ 共 %s 个\n' "$f" "$(grep -c 'DISABLED_' "$f")"
done

echo
echo "=== buffer 相关测试里的用例名 ==="
grep -hoE '(TEST|TEST_F)\([A-Za-z0-9_]+, *[A-Za-z0-9_]+' test/buffer/*.cpp 2>/dev/null | head -20 | sed 's/^/  /'

echo
echo "=== docs/p1-design.md 前 20 行 ==="
head -20 docs/p1-design.md 2>/dev/null | sed 's/^/  /'
