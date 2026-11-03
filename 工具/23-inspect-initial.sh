#!/usr/bin/env bash
cd /root/bustub_initial || exit 1

echo "===== 有 TODO(P1) 的文件 ====="
grep -rl "TODO(P1)" src 2>/dev/null | sed 's/^/  /'

echo
echo "===== p1_test.sh ====="
cat p1_test.sh 2>/dev/null

echo
echo "===== build_project.sh ====="
cat build_project.sh 2>/dev/null

echo
echo "===== test 目录 ====="
find test -name '*.cpp' | sort | sed 's/^/  /'

echo
echo "===== 测试里 DISABLED_ 的数量 ====="
for f in $(find test -name '*_test.cpp'); do
  n=$(grep -c 'DISABLED_' "$f" 2>/dev/null)
  [ "$n" -gt 0 ] && printf '  %-52s %s\n' "$f" "$n"
done
