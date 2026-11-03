#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "==> 初始化 git 仓库并做基线提交"
if [ -d .git ]; then
  echo "    已有 .git，跳过"
else
  git init -q
  cat > .gitignore <<'EOF'
build/
*.o
*.a
EOF
  git add -A
  git -c user.name="bustub-lab" -c user.email="lab@localhost" commit -q -m "课程初始代码（未实现任何 Lab）"
  echo "    已提交"
fi

echo
echo "  当前状态: $(git status --short | wc -l) 个未提交改动"
echo "  提交记录:"
git log --oneline | head -3 | sed 's/^/    /'
echo "  跟踪文件数: $(git ls-files | wc -l)"

echo
echo "==> 三个 P1 测试的用例数"
cd build
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  n=$(./test/$t --gtest_list_tests 2>/dev/null | grep -cE '^  [A-Za-z]')
  printf '    %-36s %s 个用例\n' "$t" "$n"
done

echo
echo "==> 磁盘占用"
du -sh /root/bustub /root/bustub/build 2>/dev/null
