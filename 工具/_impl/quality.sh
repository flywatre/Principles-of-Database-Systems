#!/usr/bin/env bash
cd /root/bustub/build || exit 1

echo "==> 1. make format（自动排版）"
make format > /tmp/fmt.log 2>&1
echo "   退出码: $?"
cd /root/bustub && git diff --stat | tail -8

echo
echo "==> 2. make check-lint"
cd build && make check-lint > /tmp/lint.log 2>&1
echo "   退出码: $?"
grep -iE 'error|Total errors' /tmp/lint.log | tail -5 | sed 's/^/   /'

echo
echo "==> 3. make check-clang-tidy-p1"
timeout 900 make check-clang-tidy-p1 > /tmp/tidy.log 2>&1
echo "   退出码: $?"
grep -iE 'error|warning' /tmp/tidy.log | head -8 | sed 's/^/   /'

echo
echo "==> 4. 排版后重新编译并回归测试"
make -j"$(nproc)" lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test > /tmp/re_build.log 2>&1
echo "   编译: $?"
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  out=$(timeout 300 "./test/$t" 2>&1)
  p=$(echo "$out" | grep -oE '\[  PASSED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); p=${p:-0}
  f=$(echo "$out" | grep -oE '\[  FAILED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); f=${f:-0}
  printf '   %-38s 通过 %-3s 失败 %-3s\n' "$t" "$p" "$f"
done
