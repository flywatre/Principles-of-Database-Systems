#!/usr/bin/env bash
cd /root/bustub/build || exit 1
echo "===== extendible_hash_table_test 原始输出（尾 25 行）====="
timeout 180 ./test/extendible_hash_table_test 2>&1 | tail -25 | sed 's/^/  /'
echo "  退出码: ${PIPESTATUS[0]}"

echo
echo "===== 对应源码的 TODO 位置 ====="
cd /root/bustub
grep -n "UNIMPLEMENTED\|TODO(P1)" src/container/hash/extendible_hash_table.cpp | head -12 | sed 's/^/  /'
