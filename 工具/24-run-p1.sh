#!/usr/bin/env bash
cd /root/bustub_initial/build || exit 1

echo "===== 编译 P1 的三个测试 ====="
make -j"$(nproc)" lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test > /tmp/p1c_build.log 2>&1
echo "  退出码: $?"
grep -c 'Built target' /tmp/p1c_build.log | sed 's/^/  构建 target 数: /'
if [ $? -ne 0 ]; then tail -20 /tmp/p1c_build.log; fi

echo
echo "===== 逐个运行 ====="
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  echo "--- $t ---"
  out=$(timeout 120 "./test/$t" 2>&1)
  code=$?
  echo "$out" | grep -E '^\[==========\]|^\[  PASSED  \]|^\[  FAILED  \]|YOU HAVE|TODO|what\(\)' | head -6 | sed 's/^/    /'
  echo "    退出码: $code"
  echo
done
