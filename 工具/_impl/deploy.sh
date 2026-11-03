#!/usr/bin/env bash
# 把 _impl 下的实现部署到 /root/bustub 并编译
set -uo pipefail
IMPL="/mnt/d/code/database system principle/工具/_impl"
REPO=/root/bustub

echo "==> 1. 打补丁：头文件"
python3 "$IMPL/patch_headers.py" || exit 1

echo
echo "==> 2. 拷贝三个 .cpp"
tr -d '\r' < "$IMPL/lru_k_replacer.cpp"               > "$REPO/src/buffer/lru_k_replacer.cpp"
tr -d '\r' < "$IMPL/extendible_hash_table.cpp"        > "$REPO/src/container/hash/extendible_hash_table.cpp"
tr -d '\r' < "$IMPL/buffer_pool_manager_instance.cpp" > "$REPO/src/buffer/buffer_pool_manager_instance.cpp"
echo "  src/buffer/lru_k_replacer.cpp"
echo "  src/container/hash/extendible_hash_table.cpp"
echo "  src/buffer/buffer_pool_manager_instance.cpp"

echo
echo "==> 3. 编译"
cd "$REPO/build" || exit 1
make -j"$(nproc)" lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test > /tmp/impl_build.log 2>&1
code=$?
echo "  make 退出码: $code"
if [ "$code" -ne 0 ]; then
  echo "  ---- 错误列表 ----"
  grep -E 'error:' /tmp/impl_build.log | head -15 | sed 's/^/  /'
  echo "  ---- 首个错误的上下文 ----"
  grep -B3 -A8 'error:' /tmp/impl_build.log | head -30 | sed 's/^/  /'
  exit 1
fi
echo "  编译通过"
