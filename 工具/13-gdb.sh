#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive

echo "=== 安装 gdb ==="
if ! command -v gdb >/dev/null 2>&1; then
  apt-get install -y --no-install-recommends gdb > /tmp/gdb_install.log 2>&1
fi
echo "  gdb: $(gdb --version 2>/dev/null | head -1)"

echo
echo "=== 演示：编一个 P1 测试并运行 ==="
cd /root/bustub/build || exit 1
make -j8 lru_k_replacer_test > /tmp/demo_build.log 2>&1
echo "  make 退出码: $?"
./test/lru_k_replacer_test 2>&1 | tail -8 | sed 's/^/  /'
