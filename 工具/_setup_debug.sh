#!/usr/bin/env bash
set -uo pipefail
SRC="/mnt/d/code/database system principle/工具/_vscode"
DST=/root/bustub/.vscode

echo "==> 1. 安装 VS Code 调试配置"
mkdir -p "$DST"
for f in launch.json tasks.json; do
  tr -d '\r' < "$SRC/$f" > "$DST/$f"
  echo "  $DST/$f  ($(wc -c < "$DST/$f") 字节)"
done
# JSON 语法自检
python3 -c "import json;json.load(open('$DST/launch.json'));json.load(open('$DST/tasks.json'));print('  JSON 语法: OK')" || echo "  JSON 语法错误"

echo
echo "==> 2. 验证 gdb + ASAN_OPTIONS=detect_leaks=0"
cd /root/bustub/build || exit 1
ASAN_OPTIONS=detect_leaks=0 gdb -batch -q \
  -ex "set pagination off" \
  -ex "break LRUKReplacer::RecordAccess" \
  -ex "run" \
  -ex "echo \n--- 停在哪里 ---\n" \
  -ex "bt 2" \
  -ex "echo \n--- 单步执行 ---\n" \
  -ex "next" \
  -ex "info line" \
  -ex "continue" \
  --args ./test/lru_k_replacer_test --gtest_filter='LRUKReplacerTest.SampleTest' 2>&1 \
  | grep -vE '^\[Thread|^\[New Thread|libthread_db' | head -30

echo
echo "==> 3. WSL 里有没有 code 命令（决定能否从终端装远程扩展）"
command -v code || echo "  没有 code 命令"
