#!/usr/bin/env bash
cd /root/bustub || exit 1
echo "=================== src/include/buffer/buffer_pool_manager.h ==================="
tr -d '\r' < src/include/buffer/buffer_pool_manager.h
echo
echo "=================== src/buffer/buffer_pool_manager.cpp（基类包装）==================="
tr -d '\r' < src/buffer/buffer_pool_manager.cpp
