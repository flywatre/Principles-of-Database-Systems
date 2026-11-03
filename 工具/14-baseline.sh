#!/usr/bin/env bash
# 启用 P1 的 DISABLED_ 测试并跑一遍基线
set -uo pipefail
cd /root/bustub || exit 1

echo "=== 1. 动手前的 git 状态（确认没有未提交的改动）==="
git status --short || true
echo "  HEAD: $(git rev-parse --short HEAD)"

echo
echo "=== 2. 启用 P1 测试（去掉 TEST(T, DISABLED_Name) 里的前缀）==="
FILES="test/buffer/lru_k_replacer_test.cpp test/buffer/lru_replacer_test.cpp test/buffer/buffer_pool_manager_test.cpp test/storage/page_guard_test.cpp test/storage/disk_scheduler_test.cpp"
for f in $FILES; do
  [ -f "$f" ] || continue
  before=$(grep -c ', DISABLED_' "$f")
  sed -i 's/, DISABLED_/, /g' "$f"
  after=$(grep -c ', DISABLED_' "$f")
  printf '  %-44s %s -> %s\n' "$f" "$before" "$after"
done

echo
echo "=== 3. 改动统计 ==="
git diff --stat | tail -8

echo
echo "=== 4. 编译 ==="
cd build || exit 1
make -j"$(nproc)" lru_k_replacer_test lru_replacer_test buffer_pool_manager_test page_guard_test disk_scheduler_test > /tmp/p1_build.log 2>&1
echo "  make 退出码: $?"
grep -c 'Built target' /tmp/p1_build.log | sed 's/^/  构建完成 target 数: /'

echo
echo "=== 5. 跑基线（每个二进制 90 秒超时）==="
summary=""
for t in lru_k_replacer_test lru_replacer_test disk_scheduler_test page_guard_test buffer_pool_manager_test; do
  if [ ! -x "./test/$t" ]; then
    summary="$summary$t|未构建\n"; continue
  fi
  out=$(timeout 90 "./test/$t" 2>&1)
  code=$?
  passed=$(echo "$out" | grep -oE '\[  PASSED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+')
  failed=$(echo "$out" | grep -oE '\[  FAILED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+')
  reason=""
  if [ "$code" -eq 124 ]; then reason="超时(可能死锁)"
  elif echo "$out" | grep -q 'TODO(P1)'; then reason="TODO 未实现"
  elif [ "$code" -ne 0 ]; then reason="断言失败"
  fi
  summary="$summary$t|${passed:-0}|${failed:-0}|${reason:-正常}\n"
done

echo
printf '  %-30s %8s %8s  %s\n' "测试" "通过" "失败" "原因"
echo "  ----------------------------------------------------------------"
printf "$summary" | while IFS='|' read -r name p f r; do
  [ -z "$name" ] && continue
  printf '  %-30s %8s %8s  %s\n' "$name" "$p" "$f" "$r"
done
