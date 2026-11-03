#!/usr/bin/env bash
# =============================================================================
#  run-p1.sh — 一键编译并运行 P1 的三个测试
#  由 Windows 侧的「运行实验.cmd」调用，也可在 WSL 里直接 bash /root/tools/run-p1.sh
# =============================================================================
set -uo pipefail

REPO=/root/bustub
BUILD=$REPO/build
TARGETS="lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test"

if [ -t 1 ] || [ "${1:-}" = "--color" ]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[36m'; D=$'\033[0m'; BOLD=$'\033[1m'
else
  G=''; R=''; Y=''; B=''; D=''; BOLD=''
fi

[ -d "$BUILD" ] || { echo "找不到 $BUILD，构建目录不存在"; exit 1; }
cd "$BUILD" || exit 1

printf '%s\n' "${BOLD}========================================================================${D}"
printf ' BusTub P1 — 编译并运行测试\n'
printf '%s\n' "${BOLD}========================================================================${D}"
printf ' 代码目录 : %s\n' "$REPO"
printf ' 编译器   : %s\n' "$(grep -m1 '^CMAKE_CXX_COMPILER:' CMakeCache.txt 2>/dev/null | cut -d= -f2)"
printf ' 构建类型 : %s\n' "$(grep -m1 '^CMAKE_BUILD_TYPE:' CMakeCache.txt 2>/dev/null | cut -d= -f2)"
echo

printf '%s\n' "${B}==> 编译${D}"
start=$(date +%s)
if ! make -j"$(nproc)" $TARGETS > /tmp/p1_build.log 2>&1; then
  printf '%s\n' "${R}编译失败${D}，最后 40 行："
  tail -40 /tmp/p1_build.log
  echo
  echo "完整日志: /tmp/p1_build.log"
  exit 1
fi
printf '   %sOK%s  耗时 %s 秒\n\n' "$G" "$D" "$(( $(date +%s) - start ))"

printf '%s\n' "${B}==> 运行${D}"
tp=0; tf=0
printf '  %-38s %6s %6s  %s\n' "测试" "通过" "失败" "备注"
printf '  %s\n' "------------------------------------------------------------------------"
for t in $TARGETS; do
  if [ ! -x "./test/$t" ]; then
    printf '  %-38s %6s %6s  %s\n' "$t" "-" "-" "未构建"
    continue
  fi
  out=$(timeout 300 "./test/$t" 2>&1)
  code=$?
  p=$(echo "$out" | grep -oE '\[  PASSED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); p=${p:-0}
  f=$(echo "$out" | grep -oE '\[  FAILED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); f=${f:-0}
  tp=$((tp+p)); tf=$((tf+f))

  note=""
  if echo "$out" | grep -q 'ERROR: AddressSanitizer'; then
    note="ASan 崩溃（越界/空指针）"
  elif [ "$code" -eq 124 ]; then
    note="超时（可能死锁）"
  elif echo "$out" | grep -qE 'SUMMARY: AddressSanitizer: [0-9]+ byte\(s\) leaked'; then
    note="内存泄漏"
  elif [ "$f" -eq 0 ] && [ "$p" -gt 0 ]; then
    note="${G}通过${D}"
  fi
  printf '  %-38s %6s %6s  %s\n' "$t" "$p" "$f" "$note"
done
printf '  %s\n' "------------------------------------------------------------------------"
printf '  %-38s %6s %6s\n' "合计" "$tp" "$tf"
echo

if [ "$tf" -eq 0 ] && [ "$tp" -gt 0 ]; then
  printf '%s\n\n' "${G}${BOLD}全部通过。${D}"
  exitcode=0
else
  printf '%s\n\n' "${Y}P1 还没做完：通过 $tp 个，失败 $tf 个。${D}"
  exitcode=1
fi

cat <<EOF
${BOLD}下一步${D}
  改代码    → 双击「2-打开代码编辑器.cmd」
  再跑一遍  → 双击「运行实验.cmd」
  看单条原因 → cd $BUILD && ./test/lru_k_replacer_test --gtest_filter='LRUKReplacerTest.SampleTest'
  回滚改动   → cd $REPO && git checkout .
EOF
exit $exitcode
