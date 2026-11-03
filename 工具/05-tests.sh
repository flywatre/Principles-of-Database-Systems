#!/usr/bin/env bash
# 编译全部单元测试并抽样运行，验证测试链路
set -uo pipefail
cd /root/bustub/build || exit 1

echo "=== 可用目标（节选）==="
make help 2>/dev/null | grep -E '^\s*(format|check-lint|check-clang-tidy|check-tests|check-format|submit)' | head -12

JOBS=$(nproc)
echo
echo "=== 构建全部测试（make -j$JOBS check-tests）==="
start=$(date +%s)
if make -j"$JOBS" check-tests > /tmp/tests_build.log 2>&1; then
  echo "    [ OK ] 测试构建成功，耗时 $(( $(date +%s) - start )) 秒"
else
  echo "    [FAIL] 测试构建失败，最后 40 行："
  tail -40 /tmp/tests_build.log | sed 's/^/      /'
  exit 1
fi

echo
echo "=== 测试二进制数量 ==="
ls test/*_test 2>/dev/null | wc -l | sed 's/^/    /'

echo
echo "=== 抽样运行 lru_k_replacer_test（未实现，应显示失败或 disabled）==="
timeout 120 ./test/lru_k_replacer_test --gtest_list_tests 2>&1 | head -15 | sed 's/^/    /'
