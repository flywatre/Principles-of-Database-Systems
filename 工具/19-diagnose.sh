#!/usr/bin/env bash
echo "===== 根目录 ====="
ls -la / | grep -E 'root|home'
echo
echo "===== /root 内容 ====="
ls -la /root 2>&1 | head -20
echo
echo "===== /root/bustub ====="
if [ -d /root/bustub ]; then
  echo "存在"
  ls -la /root/bustub 2>&1 | head -15
  echo "--- .git ---"
  ls -d /root/bustub/.git 2>&1
else
  echo "不存在！"
fi
echo
echo "===== 磁盘 ====="
df -h / | tail -1
echo
echo "===== 当前工作目录 ====="
pwd
