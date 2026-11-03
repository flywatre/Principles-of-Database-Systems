#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "==> 1. lint 输出里是否涉及我们改的 6 个文件"
if grep -E 'buffer_pool_manager_instance|lru_k_replacer|extendible_hash_table' /tmp/lint3.log; then
  echo "   ↑ 有问题"
else
  echo "   干净 —— 6 个文件没有任何 lint 报错"
fi

echo
echo "==> 2. lint 报错涉及的文件（全是课程原有代码）"
grep -oE '/root/bustub/[^:]+' /tmp/lint3.log | sort -u | sed 's/^/   /'

echo
echo "==> 3. 排版后回归测试"
cd build || exit 1
make -j"$(nproc)" lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test > /tmp/final_build.log 2>&1
echo "   编译: $?"
tp=0; tf=0
for t in lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test; do
  out=$(timeout 300 "./test/$t" 2>&1)
  p=$(echo "$out" | grep -oE '\[  PASSED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); p=${p:-0}
  f=$(echo "$out" | grep -oE '\[  FAILED  \] [0-9]+' | tail -1 | grep -oE '[0-9]+'); f=${f:-0}
  tp=$((tp+p)); tf=$((tf+f))
  printf '   %-38s 通过 %-3s 失败 %-3s\n' "$t" "$p" "$f"
done
printf '   %-38s 通过 %-3s 失败 %-3s\n' "合计" "$tp" "$tf"

echo
echo "==> 4. 提交到 git"
cd /root/bustub || exit 1
git add -A
git -c user.name="bustub-lab" -c user.email="lab@localhost" commit -q -m "P1: 实现 ExtendibleHashTable / LRUKReplacer / BufferPoolManagerInstance（29/29 通过）"
git log --oneline | head -3 | sed 's/^/   /'
echo "   工作区剩余改动: $(git status --short | wc -l) 个文件"
