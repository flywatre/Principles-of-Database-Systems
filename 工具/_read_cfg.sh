#!/usr/bin/env bash
cd /root/bustub || exit 1
echo "=== config.h 里的类型与常量 ==="
tr -d '\r' < src/include/common/config.h | grep -nE 'using |constexpr .*ID|INVALID' | head -20
echo
echo "=== exception.h 里的异常类 ==="
tr -d '\r' < src/include/common/exception.h | grep -nE 'class |Exception\(' | head -15
echo
echo "=== 测试里是否检查写盘/刷盘次数 ==="
grep -rn 'GetNumWrites\|GetNumFlushes\|GetFlushState' test/ | head -10 || echo "  没有"
echo
echo "=== 测试里是否引用 INVALID_FRAME_ID ==="
grep -rn 'INVALID_FRAME_ID' src/ test/ | head -5 || echo "  没有"
echo
echo "=== disk_scheduler / page 相关常量 ==="
grep -nE 'BUSTUB_PAGE_SIZE|PAGE_SIZE' src/include/common/config.h | head -5
