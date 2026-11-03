#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "==> 1. 把 build_support 下脚本转成 LF"
find build_support -name '*.py' -o -name '*.sh' | while read -r f; do
  sed -i 's/\r$//' "$f"
done
find tools -name '*.sh' 2>/dev/null | while read -r f; do sed -i 's/\r$//' "$f"; done
head -1 build_support/cpplint.py | cat -A | sed 's/^/   /'

echo
echo "==> 2. make format"
cd build && make format > /tmp/fmt3.log 2>&1
echo "   退出码: $?"
tail -2 /tmp/fmt3.log | sed 's/^/   /'

echo
echo "==> 3. make check-lint"
make check-lint > /tmp/lint3.log 2>&1
echo "   退出码: $?"
grep -E 'Total errors found' /tmp/lint3.log | tail -2 | sed 's/^/   /'
grep -E '^\s+\[.*\] .*:.*:  ' /tmp/lint3.log | head -5 | sed 's/^/   /'

echo
echo "==> 4. make check-clang-tidy-p1"
timeout 900 make check-clang-tidy-p1 > /tmp/tidy3.log 2>&1
echo "   退出码: $?"
grep -iE 'error:|warning:' /tmp/tidy3.log | head -8 | sed 's/^/   /'
tail -2 /tmp/tidy3.log | sed 's/^/   /'
