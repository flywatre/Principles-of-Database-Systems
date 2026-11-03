#!/usr/bin/env bash
# WSL 环境侦察
echo "--- 工具 ---"
for c in curl wget git apt apt-get gcc g++ cmake make python3 unzip; do
  p="$(command -v "$c" 2>/dev/null)"
  printf '%-8s %s\n' "$c" "${p:-无}"
done

echo "--- 发行版 ---"
grep -E '^(PRETTY_NAME|VERSION_CODENAME)=' /etc/os-release

echo "--- APT 源 ---"
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
  echo "(deb822) /etc/apt/sources.list.d/ubuntu.sources"
  grep -E '^(URIs|Suites):' /etc/apt/sources.list.d/ubuntu.sources | head -6
elif [ -f /etc/apt/sources.list ]; then
  grep -vE '^\s*(#|$)' /etc/apt/sources.list | head -6
else
  echo "没有找到 sources 文件"
fi

echo "--- 内存限制 ---"
cat /proc/meminfo | head -1

echo "--- 网络 (10 秒超时) ---"
for u in https://github.com https://codeload.github.com https://mirrors.tuna.tsinghua.edu.cn; do
  code="$(timeout 12 curl -sS -o /dev/null -w '%{http_code}' "$u" 2>/dev/null)" || code="超时"
  printf '%-42s %s\n' "$u" "$code"
done

echo "--- DNS ---"
cat /etc/resolv.conf 2>/dev/null | grep -E '^nameserver' | head -2
