#!/usr/bin/env bash
# 诊断 ASan 启动崩溃：检查 vm.mmap_rnd_bits（新内核上 >28 会让 ASan 崩）
echo "=== 内核参数 ==="
echo "mmap_rnd_bits     = $(cat /proc/sys/vm/mmap_rnd_bits 2>/dev/null)"
echo "mmap_rnd_bits_max = $(cat /proc/sys/vm/mmap_rnd_bits_max 2>/dev/null)"
echo "内核: $(uname -r)"

echo
echo "=== 单独构建并运行 orset_test ==="
cd /root/bustub/build || exit 1
make -j8 orset_test > /tmp/orset_build.log 2>&1
echo "构建退出码: $?"
if [ -x ./test/orset_test ]; then
  echo "--- 直接运行 --gtest_list_tests ---"
  ./test/orset_test --gtest_list_tests 2>&1 | head -20
  echo "运行退出码: ${PIPESTATUS[0]}"
else
  echo "二进制不存在："
  tail -20 /tmp/orset_build.log
fi
