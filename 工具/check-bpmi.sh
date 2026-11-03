#!/usr/bin/env bash
cd /root/bustub/build || exit 1
timeout 300 ./test/buffer_pool_manager_instance_test > /tmp/bpmi.log 2>&1
echo "退出码: $?"
echo "--- 最后 12 行 ---"
tail -12 /tmp/bpmi.log
echo "--- AddressSanitizer ERROR 出现次数 ---"
grep -c 'ERROR: AddressSanitizer' /tmp/bpmi.log
echo "--- 是否打印了汇总 ---"
grep -c 'tests from .* test suite ran' /tmp/bpmi.log
