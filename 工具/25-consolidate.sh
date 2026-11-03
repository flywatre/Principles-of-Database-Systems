#!/usr/bin/env bash
# 把课程代码设为唯一的 /root/bustub，删掉之前克隆的官方 master（版本不同，留着只会混淆）
set -uo pipefail

echo "==> 1/4 删除官方 master 克隆（942MB，可随时重新 git clone）"
if [ -d /root/bustub ] && [ -f /root/bustub/build_support/packages.sh ]; then
  if [ ! -d /root/bustub/src/include/buffer ] || [ -f /root/bustub/src/buffer/arc_replacer.cpp ]; then
    rm -rf /root/bustub
    echo "    已删除"
  else
    echo "    未删除（看起来不是 master 克隆）"
  fi
fi

echo
echo "==> 2/4 课程代码搬为 /root/bustub"
if [ -d /root/bustub_initial ]; then
  rm -rf /root/bustub_initial/build
  mv /root/bustub_initial /root/bustub
  echo "    完成"
else
  echo "    /root/bustub_initial 不存在，检查 /root/bustub 是否已是课程代码"
fi

echo
echo "==> 3/4 重新配置并编译（换路径后 CMake 缓存失效，必须重来）"
cd /root/bustub || exit 1
mkdir -p build && cd build || exit 1
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=clang-15 -DCMAKE_CXX_COMPILER=clang++-15 .. > /tmp/rc_cmake.log 2>&1
echo "    cmake 退出码: $?"
start=$(date +%s)
make -j"$(nproc)" > /tmp/rc_build.log 2>&1
echo "    make 退出码: $?  耗时 $(( $(date +%s) - start )) 秒"

echo
echo "==> 4/4 验证"
cd /root/bustub || exit 1
echo "    路径: $(pwd)   版本: $(grep -m1 VERSION CMakeLists.txt | tr -d ' ')"
echo "    shell: $(ls -lh build/bin/bustub-shell 2>/dev/null | awk '{print $5}')"
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  n=$(timeout 120 "./build/test/$t" 2>&1 | grep -cE '^\[  FAILED  \]')
  printf '    %-36s 失败用例 %s 个\n' "$t" "$n"
done
