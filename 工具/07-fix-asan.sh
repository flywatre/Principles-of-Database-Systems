#!/usr/bin/env bash
# =============================================================================
#  07-fix-asan.sh — 修复新内核 + ASan 不兼容导致的随机段错误
#
#  背景：Linux 6.6+ 把 vm.mmap_rnd_bits 提到 32，而 ASan 的 shadow memory
#        布局要求随机化位数 <= 28，否则程序启动时可能随机崩溃（无任何输出）。
#        Bustub Debug 模式默认开 -fsanitize=address，所以症状是"测试时好时坏"。
# =============================================================================
set -uo pipefail

OLD=$(cat /proc/sys/vm/mmap_rnd_bits)
echo "当前 mmap_rnd_bits = $OLD"

if [ "$OLD" -gt 28 ] 2>/dev/null; then
  echo "降低到 28 ..."
  sysctl -w vm.mmap_rnd_bits=28
  cat > /etc/sysctl.d/99-bustub-asan.conf <<'EOF'
# Bustub 的 Debug 构建启用 AddressSanitizer，
# 而 ASan 要求 mmap 随机化位数 <= 28，否则会随机段错误。
vm.mmap_rnd_bits = 28
EOF
  echo "已写入 /etc/sysctl.d/99-bustub-asan.conf（重启 WSL 后仍生效）"
else
  echo "无需修改"
fi
echo "现在 mmap_rnd_bits = $(cat /proc/sys/vm/mmap_rnd_bits)"

echo
echo "=== 连续 5 次运行 orset_test，验证不再随机崩溃 ==="
cd /root/bustub/build
ok=0
for i in 1 2 3 4 5; do
  if ./test/orset_test --gtest_list_tests > /dev/null 2>&1; then
    ok=$((ok+1)); printf '  第 %d 次: 正常\n' "$i"
  else
    printf '  第 %d 次: 崩溃(退出码 %d)\n' "$i" "$?"
  fi
done
echo "  成功 $ok/5"

echo
echo "=== 重新构建全部测试 ==="
JOBS=$(nproc)
start=$(date +%s)
if make -j"$JOBS" check-tests > /tmp/tests_build2.log 2>&1; then
  echo "  [ OK ] 耗时 $(( $(date +%s) - start )) 秒"
  echo "  测试二进制数量: $(ls test/*_test 2>/dev/null | wc -l)"
else
  echo "  [FAIL] 最后 30 行："
  tail -30 /tmp/tests_build2.log | sed 's/^/    /'
  exit 1
fi
