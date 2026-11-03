#!/usr/bin/env bash
cd /root/bustub/build || exit 1

echo "##################### 1. 增量编译（改了 .cpp 之后）#####################"
time make -j"$(nproc)" lru_k_replacer_test 2>&1 | tail -3

echo
echo "##################### 2. 一个真实的 gdb 会话 #####################"
echo "目标：在 LRUKReplacer::Size() 下断点，看它被谁调用、返回什么"
echo
gdb -batch -q \
  -ex "set pagination off" \
  -ex "set print pretty on" \
  -ex "break LRUKReplacer::Size()" \
  -ex "run" \
  -ex "echo \n--- 调用栈（谁在调用 Size）---\n" \
  -ex "bt 4" \
  -ex "echo \n--- 当前对象的成员变量 ---\n" \
  -ex "print curr_size_" \
  -ex "print replacer_size_" \
  -ex "echo \n--- 继续执行，看断言怎么失败 ---\n" \
  -ex "continue" \
  --args ./test/lru_k_replacer_test --gtest_filter='LRUKReplacerTest.SampleTest' 2>&1 | grep -vE '^\[Thread|^\[New Thread|libthread_db' | head -50
