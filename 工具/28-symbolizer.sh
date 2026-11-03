#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
cd /root/bustub/build || exit 1

echo "==> 安装 llvm-15（提供 llvm-symbolizer）"
if ! command -v llvm-symbolizer >/dev/null 2>&1; then
  apt-get install -y --no-install-recommends llvm-15 > /tmp/llvm15.log 2>&1
  for v in /usr/bin/llvm-symbolizer-15 /usr/lib/llvm-15/bin/llvm-symbolizer; do
    [ -x "$v" ] && ln -sf "$v" /usr/local/bin/llvm-symbolizer && break
  done
fi
echo "  llvm-symbolizer: $(command -v llvm-symbolizer || echo 未找到)"

echo
echo "==> 重新运行 extendible_hash_table_test（带符号化）"
export ASAN_SYMBOLIZER_PATH="$(command -v llvm-symbolizer)"
timeout 180 ./test/extendible_hash_table_test 2>&1 | grep -E 'ERROR|SUMMARY|#[0-9]+ .*extendible|#[0-9]+ .*hash' | head -12 | sed 's/^/  /'
