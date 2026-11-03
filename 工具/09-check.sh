#!/usr/bin/env bash
cd /root/bustub/build || exit 1

echo "=== buffer_pool_manager_test 实际输出（前 25 行）==="
timeout 120 ./test/buffer_pool_manager_test 2>&1 | head -25 | sed 's/^/  /'

echo
echo "=== trie_test 失败原因 ==="
timeout 120 ./test/trie_test 2>&1 | grep -E 'TODO|Failure|error|DISABLED' | head -6 | sed 's/^/  /'

echo
echo "=== make 目标检查 ==="
for t in format check-lint check-clang-tidy-p1 check-tests check-format submit-p1; do
  if make -n "$t" > /dev/null 2>&1; then
    echo "  $t : 存在"
  else
    echo "  $t : 不存在"
  fi
done

echo
echo "=== Makefile 里所有 check-/format/submit 目标 ==="
grep -oE '^[a-z0-9-]*(check|format|submit|build)[a-z0-9-]*:' Makefile 2>/dev/null | tr -d ':' | sort -u | head -25 | sed 's/^/  /'
