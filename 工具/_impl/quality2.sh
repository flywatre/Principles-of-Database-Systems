#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "==> 修补 build_support 下脚本的可执行权限"
chmod +x build_support/*.py
ls -l build_support/cpplint.py build_support/run_clang_format.py build_support/run_clang_tidy.py | sed 's/^/  /'

echo
echo "==> make format"
cd build && make format > /tmp/fmt2.log 2>&1
echo "   退出码: $?"
tail -3 /tmp/fmt2.log | sed 's/^/   /'

echo
echo "==> make check-lint"
make check-lint > /tmp/lint2.log 2>&1
echo "   退出码: $?"
grep -E 'Total errors|error' /tmp/lint2.log | tail -6 | sed 's/^/   /'

echo
echo "==> make check-clang-tidy-p1（可能较慢）"
timeout 900 make check-clang-tidy-p1 > /tmp/tidy2.log 2>&1
echo "   退出码: $?"
grep -iE 'error|warning:' /tmp/tidy2.log | head -10 | sed 's/^/   /'
tail -3 /tmp/tidy2.log | sed 's/^/   /'
