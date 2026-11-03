#!/usr/bin/env bash
# 最终验证：区分"环境问题"与"Lab 未实现"
cd /root/bustub/build || exit 1

echo "=== 测试二进制（编译产物）==="
echo "  数量: $(ls test/*_test 2>/dev/null | wc -l)"
ls test/*_test 2>/dev/null | head -8 | sed 's/^/    /'
echo "    ..."

echo
echo "=== check-tests 日志里有没有编译错误 ==="
if grep -qiE 'error:|Error [0-9]+$' /tmp/tests_build2.log 2>/dev/null; then
  echo "  有编译错误："
  grep -iE 'error:' /tmp/tests_build2.log | head -5 | sed 's/^/    /'
else
  echo "  无编译错误（全部目标构建成功，失败发生在 ctest 运行阶段）"
fi
echo "  构建完成的 target 数: $(grep -c 'Built target' /tmp/tests_build2.log 2>/dev/null)"

echo
echo "=== 跑一个与 Lab 无关的测试，验证 GTest 链路 ==="
for t in trie_test hyperloglog_test skiplist_test; do
  if [ -x "./test/$t" ]; then
    out=$(timeout 120 "./test/$t" 2>&1)
    code=$?
    pass=$(echo "$out" | grep -oE '\[  PASSED  \] [0-9]+ tests?' | head -1)
    fail=$(echo "$out" | grep -oE '\[  FAILED  \] [0-9]+ tests?' | head -1)
    printf '  %-20s 退出码=%-3s %s %s\n' "$t" "$code" "${pass:-无通过信息}" "${fail}"
  fi
done

echo
echo "=== 跑一个 P1 测试，确认失败原因是 TODO 而非环境 ==="
out=$(timeout 120 ./test/buffer_pool_manager_test 2>&1)
echo "$out" | grep -E 'TODO|what\(\)|FAILED|PASSED' | head -5 | sed 's/^/    /'

echo
echo "=== 可用 make 目标 ==="
make help 2>/dev/null | grep -E '^\s*(format|check-lint|check-clang-tidy|check-tests|submit|check-format)' | sed 's/^/  /'
