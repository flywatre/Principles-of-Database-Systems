#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "=== 六个文件的行数 ==="
for f in src/include/container/hash/extendible_hash_table.h src/container/hash/extendible_hash_table.cpp \
         src/include/buffer/lru_k_replacer.h src/buffer/lru_k_replacer.cpp \
         src/include/buffer/buffer_pool_manager_instance.h src/buffer/buffer_pool_manager_instance.cpp; do
  printf '  %-58s %4s 行\n' "$f" "$(wc -l < "$f")"
done

echo
echo "=== 相对初始基线的改动 ==="
git diff --stat 1490cc2 HEAD | tail -10

echo
echo "=== 每个测试文件的用例数 ==="
cd build
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  n=$(./test/$t --gtest_list_tests 2>/dev/null | grep -cE '^  [A-Za-z]')
  printf '  %-38s %s\n' "$t" "$n"
done

echo
echo "=== 构建耗时（全量重编一次）==="
rm -rf /tmp/timing_build && touch ../src/buffer/lru_k_replacer.cpp
/usr/bin/time -f "  耗时 %e 秒" make -j"$(nproc)" lru_k_replacer_test 2>&1 | tail -2

echo
echo "=== 提交记录 ==="
cd .. && git log --oneline | head -3
