#!/usr/bin/env bash
cd /root/bustub || exit 1
echo "===== BufferPoolManagerTest.VeryBasicTest ====="
grep -n -A 34 'VeryBasicTest' test/buffer/buffer_pool_manager_test.cpp | sed -n '1,36p'
echo
echo "===== buffer_pool_manager.h 里声明的接口 ====="
grep -nE '^ *(auto|void|bool|explicit) ' src/include/buffer/buffer_pool_manager.h | head -16
