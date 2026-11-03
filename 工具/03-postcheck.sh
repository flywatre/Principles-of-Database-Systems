#!/usr/bin/env bash
# 冒烟测试 + clang-15 可用性检查
cd /root/bustub/build || exit 1

echo "=== bustub-shell 冒烟测试 ==="
printf '\\dt\n\\q\n' | timeout 60 ./bin/bustub-shell 2>&1 | head -20
echo "退出码: ${PIPESTATUS[0]}"

echo
echo "=== clang 家族版本可用性 ==="
for p in clang-14 clang-15 clang-format-15 clang-tidy-15 clang-tools-15; do
  v="$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/{print $2}')"
  printf '%-18s %s\n' "$p" "${v:-不可用}"
done

echo
echo "=== 当前已安装的 clang 工具 ==="
ls /usr/bin/clang* /usr/bin/clang-format* /usr/bin/clang-tidy* 2>/dev/null | sed 's/^/  /'

echo
echo "=== 构建产物 ==="
ls -lh bin/ | tail -10
