#!/usr/bin/env bash
cd /root/bustub/build || exit 1

echo "===== 编译 P1 三个测试 ====="
make -j"$(nproc)" lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test > /tmp/p1_final.log 2>&1
echo "  退出码: $?"
echo "  二进制:"
ls -1 test/lru_k_replacer_test test/extendible_hash_table_test test/buffer_pool_manager_instance_test 2>&1 | sed 's/^/    /'

echo
echo "===== 逐个运行（统计通过/失败）====="
total_p=0; total_f=0
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  out=$(timeout 180 "./test/$t" 2>&1)
  p=$(echo "$out" | grep -oE '\[  PASSED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); p=${p:-0}
  f=$(echo "$out" | grep -oE '\[  FAILED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); f=${f:-0}
  total_p=$((total_p+p)); total_f=$((total_f+f))
  printf '  %-36s 通过 %-3s 失败 %-3s\n' "$t" "$p" "$f"
done
echo "  --------------------------------------------------"
printf '  %-36s 通过 %-3s 失败 %-3s\n' "合计" "$total_p" "$total_f"
