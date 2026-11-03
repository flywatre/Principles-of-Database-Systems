#!/usr/bin/env bash
cd /root/bustub || exit 1

echo "===== VS Code server 状态 ====="
ls /root/.vscode-server/bin 2>/dev/null | sed 's/^/  commit: /'
echo "  已安装扩展:"
ls /root/.vscode-server/extensions 2>/dev/null | sed 's/^/    /'

echo
echo "===== 你要改的第一个文件：src/include/buffer/lru_k_replacer.h ====="
sed -n '1,200p' src/include/buffer/lru_k_replacer.h

echo
echo "===== 对应的 .cpp 骨架 ====="
cat src/buffer/lru_k_replacer.cpp
