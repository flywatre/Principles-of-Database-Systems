#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "=== python 相关命令 ==="
for c in python python3; do printf '  %-8s %s\n' "$c" "$(command -v $c || echo 缺失)"; done
python --version 2>&1 | sed 's/^/  /'

echo
echo "=== build_support 下脚本的权限 ==="
ls -l build_support/*.py build_support/*.sh 2>/dev/null | sed 's/^/  /'

echo
echo "=== Makefile 里 check-lint / check-clang-tidy 的定义 ==="
grep -n -A4 'check-lint:\|check-clang-tidy-p1:\|^format:' CMakeLists.txt | head -30 | sed 's/^/  /'
grep -rn 'cpplint' CMakeLists.txt build_support/*.cmake 2>/dev/null | head -10 | sed 's/^/  /'

echo
echo "=== 实际执行时用的命令（cmake 生成的）==="
grep -rn 'cpplint\|clang-tidy' build/CMakeFiles/check-lint.dir/build.make 2>/dev/null | head -6 | sed 's/^/  /'
grep -rn 'clang-tidy' build/CMakeFiles/check-clang-tidy-p1.dir/build.make 2>/dev/null | head -6 | sed 's/^/  /'
