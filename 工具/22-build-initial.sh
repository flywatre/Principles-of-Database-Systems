#!/usr/bin/env bash
# =============================================================================
#  解开课程发的 bustub_initial.zip 并编译验证
#  不动 /root/bustub（那是官方 master 克隆，保留作对照）
# =============================================================================
set -uo pipefail
ZIP="/mnt/d/code/database system principle/bustub_initial.zip"
DEST=/root/bustub_initial
WORK=/root/.unzip_tmp

echo "==> 1/6 解压"
[ -f "$ZIP" ] || { echo "找不到压缩包: $ZIP"; exit 1; }
rm -rf "$WORK" "$DEST"
mkdir -p "$WORK"
unzip -q "$ZIP" -d "$WORK" || { echo "解压失败"; exit 1; }
# 去掉压缩包里的顶层目录 bustub_initial/ 和 macOS 垃圾目录
if [ -d "$WORK/bustub_initial" ]; then
  mv "$WORK/bustub_initial" "$DEST"
else
  mv "$WORK" "$DEST"
fi
rm -rf "$WORK" "$DEST/__MACOSX"
echo "    解压到 $DEST"

echo
echo "==> 2/6 修复权限与换行符"
chmod +x "$DEST"/build_support/*.sh "$DEST"/tools/*.sh 2>/dev/null
find "$DEST/build_support" -name '*.sh' -exec sed -i 's/\r$//' {} \; 2>/dev/null
echo "    done"

echo
echo "==> 3/6 版本与内容"
sed -n '1,12p' "$DEST/CMakeLists.txt" | grep -iE 'version|project' | sed 's/^/    /'
echo "    顶层条目:"
ls -1 "$DEST" | head -16 | sed 's/^/      /'
echo "    各 Lab 的 TODO 数量:"
for p in P0 P1 P2 P3 P4; do
  n=$(grep -rl "TODO($p)" "$DEST/src" 2>/dev/null | wc -l)
  printf '      %s: %s 个文件\n' "$p" "$n"
done
echo "    有没有 arc_replacer（新版特征）:"
[ -f "$DEST/src/buffer/arc_replacer.cpp" ] && echo "      有" || echo "      无 —— 说明是较早的 LRU-K 版本"
echo "    docs 目录:"
ls -1 "$DEST/docs" 2>/dev/null | sed 's/^/      /' || echo "      (没有 docs 目录)"

echo
echo "==> 4/6 与官方 master 克隆的差异（仅列数量）"
if [ -d /root/bustub ]; then
  a=$(cd "$DEST" && find src test -type f | wc -l)
  b=$(cd /root/bustub && find src test -type f | wc -l)
  echo "    压缩包 src+test 文件数: $a"
  echo "    master   src+test 文件数: $b"
  echo "    src 下比 master 少的文件（前 8 个）:"
  comm -23 <(cd "$DEST" && find src -type f | sort) <(cd /root/bustub && find src -type f | sort) | head -8 | sed 's/^/      /'
fi

echo
echo "==> 5/6 CMake 配置"
cd "$DEST" || exit 1
mkdir -p build
cd build || exit 1
if cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=clang-15 -DCMAKE_CXX_COMPILER=clang++-15 .. > /tmp/initial_cmake.log 2>&1; then
  echo "    [ OK ] 配置成功"
  grep -E 'Build mode|sanitizer|clang-format at' /tmp/initial_cmake.log | sed 's/^/      /'
else
  echo "    [FAIL] 配置失败："
  tail -25 /tmp/initial_cmake.log | sed 's/^/      /'
  exit 1
fi

echo
echo "==> 6/6 编译"
JOBS=$(nproc)
start=$(date +%s)
if make -j"$JOBS" > /tmp/initial_build.log 2>&1; then
  echo "    [ OK ] 编译成功，耗时 $(( $(date +%s) - start )) 秒"
  ls -lh bin/ | grep -E 'shell' | sed 's/^/      /'
else
  echo "    [FAIL] 编译失败，最后 30 行："
  tail -30 /tmp/initial_build.log | sed 's/^/      /'
  exit 1
fi
