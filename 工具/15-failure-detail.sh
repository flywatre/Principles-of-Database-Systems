#!/usr/bin/env bash
cd /root/bustub/build || exit 1

echo "=== lru_k_replacer_test 的失败详情 ==="
timeout 90 ./test/lru_k_replacer_test 2>&1 | head -18 | sed 's/^/  /'

echo
echo "=== buffer_pool_manager_test 第一条失败 ==="
timeout 90 ./test/buffer_pool_manager_test --gtest_filter='*VeryBasicTest*' 2>&1 | head -14 | sed 's/^/  /'

echo
echo "=== 对应的 TODO 位置 ==="
cd /root/bustub
grep -n "TODO(P1)" src/buffer/lru_k_replacer.cpp | head -3 | sed 's/^/  /'
grep -n "TODO(P1)" src/buffer/buffer_pool_manager.cpp | head -3 | sed 's/^/  /'
