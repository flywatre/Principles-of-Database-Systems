#!/usr/bin/env bash
# =============================================================================
#  04-clang.sh — 安装 clang-15 工具链，切换编译器，重新构建
#  cmake 找的是不带版本号的 clang-format / clang-tidy，所以要建 alternatives
# =============================================================================
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

log()  { printf '\n==> %s\n' "$*"; }
ok()   { printf '    [ OK ] %s\n' "$*"; }
warn() { printf '    [WARN] %s\n' "$*"; }
die()  { printf '\n    [FAIL] %s\n' "$*" >&2; exit 1; }

# -----------------------------------------------------------------------------
log "1/4 安装 clang-15 全家桶"
# -----------------------------------------------------------------------------
PKGS="clang-15 clang-format-15 clang-tidy-15 clang-tools-15"
apt-get install -y --no-install-recommends $PKGS || die "clang-15 安装失败"
ok "clang $(clang-15 --version | head -1 | awk '{print $3}')"

# -----------------------------------------------------------------------------
log "2/4 注册不带版本号的命令"
# -----------------------------------------------------------------------------
for tool in clang clang++ clang-format clang-tidy clang-apply-replacements clang-check; do
  if [ -x "/usr/bin/${tool}-15" ]; then
    update-alternatives --install "/usr/bin/$tool" "$tool" "/usr/bin/${tool}-15" 150 >/dev/null 2>&1 || \
      ln -sf "/usr/bin/${tool}-15" "/usr/bin/$tool"
    printf '    %-26s -> %s\n' "$tool" "$(readlink -f "/usr/bin/$tool")"
  fi
done
# clang-check 的真实二进制名可能不同，忽略缺失
ok "已注册"

# -----------------------------------------------------------------------------
log "3/4 用 clang-15 重新配置并编译"
# -----------------------------------------------------------------------------
cd /root/bustub || die "找不到 /root/bustub"
rm -rf build
mkdir -p build
cd build || die "无法进入 build"

if ! cmake -DCMAKE_BUILD_TYPE=Debug \
           -DCMAKE_C_COMPILER=clang-15 \
           -DCMAKE_CXX_COMPILER=clang++-15 .. > /tmp/cmake_clang.log 2>&1; then
  warn "clang-15 配置失败，回退 gcc"
  tail -20 /tmp/cmake_clang.log | sed 's/^/      /'
  rm -rf build && mkdir build && cd build
  cmake -DCMAKE_BUILD_TYPE=Debug .. > /tmp/cmake_gcc.log 2>&1 || die "gcc 配置也失败"
fi

grep -E 'clang-format|clang-tidy|recommend that you use' /tmp/cmake_clang.log 2>/dev/null | sed 's/^/      /' | head -5
ok "CMake 配置完成（$(grep -m1 '^CMAKE_CXX_COMPILER:' CMakeCache.txt | cut -d= -f2)）"

JOBS=$(nproc)
echo "    make -j$JOBS ..."
if ! make -j"$JOBS" > /tmp/build_clang.log 2>&1; then
  warn "clang-15 编译失败，最后 30 行："
  tail -30 /tmp/build_clang.log | sed 's/^/      /'
  echo "    --- 回退到 gcc ---"
  rm -rf /root/bustub/build && mkdir -p /root/bustub/build && cd /root/bustub/build
  cmake -DCMAKE_BUILD_TYPE=Debug .. > /dev/null 2>&1 || die "gcc 配置失败"
  make -j"$JOBS" > /tmp/build_gcc.log 2>&1 || { tail -30 /tmp/build_gcc.log; die "gcc 编译也失败"; }
  ok "已回退 gcc 并编译成功"
else
  ok "clang-15 编译成功"
fi

# -----------------------------------------------------------------------------
log "4/4 验证"
# -----------------------------------------------------------------------------
[ -x bin/bustub-shell ] || die "没有生成 bustub-shell"
ok "bustub-shell: $(ls -lh bin/bustub-shell | awk '{print $5}')"

echo "    编译器 : $(grep -m1 '^CMAKE_CXX_COMPILER:' CMakeCache.txt | cut -d= -f2)"
echo "    clang-format : $(command -v clang-format)  $(clang-format --version 2>/dev/null | head -1)"
echo "    clang-tidy   : $(command -v clang-tidy)  $(clang-tidy --version 2>/dev/null | sed -n 2p)"

echo
echo "=== 冒烟测试（应当停在 TODO(P1)，那是未实现的 Lab 代码）==="
printf '\\dt\n\\q\n' | timeout 60 ./bin/bustub-shell 2>&1 | head -5
