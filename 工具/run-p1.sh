#!/usr/bin/env bash
# =============================================================================
#  run-p1.sh — 一键编译并运行 P1 的三个测试
#  由「运行实验.cmd」调用，也可在仓库根目录运行 bash 工具/run-p1.sh
# =============================================================================
set -uo pipefail

REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../bustub" && pwd -P) || exit 1
BUILD=$REPO/build
BUILD_LOG=$BUILD/p1_build.log
TARGETS="lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test"

if [ -t 1 ] || [ "${1:-}" = "--color" ]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[36m'; D=$'\033[0m'; BOLD=$'\033[1m'
else
  G=''; R=''; Y=''; B=''; D=''; BOLD=''
fi

mkdir -p "$BUILD" || exit 1
cd "$BUILD" || exit 1
: > "$BUILD_LOG" || exit 1

if [ ! -f CMakeCache.txt ]; then
  printf '%s\n' "${B}==> 配置 Debug 构建${D}"
  if ! cmake -S "$REPO" -B "$BUILD" -DCMAKE_BUILD_TYPE=Debug >> "$BUILD_LOG" 2>&1; then
    rm -f -- CMakeCache.txt  # 下次运行时重新配置
    tail -40 "$BUILD_LOG"
    printf '配置失败，完整日志见 %s\n' "$BUILD_LOG"
    exit 1
  fi
fi

printf '%s\n' "${BOLD}========================================================================${D}"
printf ' BusTub P1 — 编译并运行测试\n'
printf '%s\n' "${BOLD}========================================================================${D}"
printf ' 代码目录 : %s\n' "$REPO"
printf ' 编译器   : %s\n' "$(grep -m1 '^CMAKE_CXX_COMPILER:' CMakeCache.txt 2>/dev/null | cut -d= -f2)"
printf ' 构建类型 : %s\n' "$(grep -m1 '^CMAKE_BUILD_TYPE:' CMakeCache.txt 2>/dev/null | cut -d= -f2)"
echo

printf '%s\n' "${B}==> 编译${D}"
start=$(date +%s)
if ! cmake --build . --parallel "${CMAKE_BUILD_PARALLEL_LEVEL:-$(nproc)}" --target $TARGETS >> "$BUILD_LOG" 2>&1; then
  printf '%s\n' "${R}编译失败${D}，最后 40 行："
  tail -40 "$BUILD_LOG"
  echo
  printf '完整日志见 %s\n' "$BUILD_LOG"
  exit 1
fi
printf '   %sOK%s  耗时 %s 秒\n\n' "$G" "$D" "$(( $(date +%s) - start ))"

# 临时数据库留在 Linux 文件系统，避免在 Windows 挂载目录频繁读写。
TEST_DIR=$(mktemp -d /tmp/bustub-p1.XXXXXXXX) || exit 1
trap 'rm -r -- "$TEST_DIR"' EXIT
cd "$TEST_DIR" || exit 1

printf '%s\n' "${B}==> 运行${D}"
tp=0; tf=0
failed_suites=0
printf '  %-38s %6s %6s  %s\n' "测试" "通过" "失败" "备注"
printf '  %s\n' "------------------------------------------------------------------------"
for t in $TARGETS; do
  test_binary=$BUILD/test/$t
  if [ ! -x "$test_binary" ]; then
    printf '  %-38s %6s %6s  %s\n' "$t" "-" "-" "未构建"
    failed_suites=$((failed_suites+1))
    continue
  fi
  out=$(timeout 300 "$test_binary" --gtest_color=no 2>&1)
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
  elif [ "$code" -ne 0 ]; then
    note="运行失败（退出码 $code）"
  elif [ "$f" -gt 0 ]; then
    note="有用例失败"
  elif [ "$p" -eq 0 ]; then
    note="没有通过的用例"
  else
    note="${G}通过${D}"
  fi
  printf '  %-38s %6s %6s  %s\n' "$t" "$p" "$f" "$note"
  if [ "$code" -ne 0 ] || [ "$f" -gt 0 ] || [ "$p" -eq 0 ]; then
    failed_suites=$((failed_suites+1))
    printf '%s\n' "$out"
  fi
done
printf '  %s\n' "------------------------------------------------------------------------"
printf '  %-38s %6s %6s\n' "合计" "$tp" "$tf"
echo

if [ "$failed_suites" -eq 0 ]; then
  printf '%s\n\n' "${G}${BOLD}全部通过。${D}"
  exitcode=0
else
  printf '%s\n\n' "${Y}P1 有 $failed_suites 个测试套件未通过。${D}"
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
