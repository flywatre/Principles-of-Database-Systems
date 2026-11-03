#!/usr/bin/env bash
set -u
echo "===== 系统 ====="
grep PRETTY_NAME /etc/os-release
echo "内核: $(uname -r)   架构: $(uname -m)   核心: $(nproc)"

echo
echo "===== 源码仓库 ====="
cd /root/bustub || { echo "无法进入"; exit 1; }
echo "路径  : $(pwd)"
echo "commit: $(git rev-parse --short HEAD)  分支: $(git rev-parse --abbrev-ref HEAD)"
echo "改动  : $(git status --short | wc -l) 个文件"
echo "clang : $(clang++ --version | head -1)"

echo
echo "===== 编译验证（增量）====="
cd build || { echo "没有 build 目录"; exit 1; }
make -j8 lru_k_replacer_test 2>&1 | tail -3
echo "退出码: $?"

echo
echo "===== 跑一个已启用的测试（预期失败，因为 Lab 未实现）====="
./test/lru_k_replacer_test 2>&1 | tail -3
