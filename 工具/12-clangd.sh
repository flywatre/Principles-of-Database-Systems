#!/usr/bin/env bash
# 装 clangd 代码补全 + 确认 compile_commands.json
export DEBIAN_FRONTEND=noninteractive
cd /root/bustub || exit 1

echo "=== compile_commands.json ==="
find build -maxdepth 1 -name 'compile_commands.json' -exec ls -lh {} \; 2>/dev/null || echo "  没有"

echo
echo "=== 安装 clangd-15（给 IDE 用）==="
if ! command -v clangd >/dev/null 2>&1; then
  apt-get install -y --no-install-recommends clangd-15 > /tmp/clangd_install.log 2>&1
  ln -sf /usr/bin/clangd-15 /usr/local/bin/clangd 2>/dev/null
fi
echo "  clangd: $(command -v clangd)  $(clangd --version 2>/dev/null | head -1)"

echo
echo "=== 目录大小 ==="
du -sh /root/bustub/build /root/bustub/src 2>/dev/null
