#!/usr/bin/env bash
set -uo pipefail
cd /root/bustub || exit 1

echo "==> 1. 还原与实验一无关的格式化改动"
git checkout 1490cc2 -- test/primer/starter_trie_test.cpp
echo "   test/primer/starter_trie_test.cpp 已还原"

echo "==> 2. 删掉误提交的 pyc"
rm -rf build_support/__pycache__
echo "   build_support/__pycache__ 已删除"

echo "==> 3. 把这些路径加进 .gitignore"
if ! grep -q '__pycache__' .gitignore; then
  printf '\n# python bytecode\n__pycache__/\n*.pyc\n' >> .gitignore
fi

echo "==> 4. 回归测试"
cd build || exit 1
make -j"$(nproc)" lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test > /tmp/clean_build.log 2>&1
echo "   编译: $?"
tp=0; tf=0
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  out=$(timeout 300 "./test/$t" 2>&1)
  p=$(echo "$out" | grep -oE '\[  PASSED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); p=${p:-0}
  f=$(echo "$out" | grep -oE '\[  FAILED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); f=${f:-0}
  tp=$((tp+p)); tf=$((tf+f))
done
printf '   合计 通过 %s 失败 %s\n' "$tp" "$tf"

echo "==> 5. 重新提交"
cd /root/bustub
git add -A
git -c user.name="bustub-lab" -c user.email="lab@localhost" commit -q -m "P1: 清理无关格式化改动，仅保留三个部件的实现"
echo
echo "=== 最终改动清单 ==="
git diff --stat 1490cc2 HEAD | sed 's/^/  /'
