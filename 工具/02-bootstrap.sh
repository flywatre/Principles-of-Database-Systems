#!/usr/bin/env bash
# =============================================================================
#  02-bootstrap.sh — 换源、装基础工具链、拉取 bustub 源码
#  在 WSL 的 Ubuntu 22.04 里以 root 执行
# =============================================================================
set -uo pipefail

export DEBIAN_FRONTEND=noninteractive
CODENAME=jammy
MIRROR=https://mirrors.tuna.tsinghua.edu.cn/ubuntu

log()  { printf '\n==> %s\n' "$*"; }
ok()   { printf '    [ OK ] %s\n' "$*"; }
warn() { printf '    [WARN] %s\n' "$*"; }
die()  { printf '\n    [FAIL] %s\n' "$*" >&2; exit 1; }

# -----------------------------------------------------------------------------
log "1/4 切换到清华镜像源"
# -----------------------------------------------------------------------------
STAMP=$(date +%Y%m%d-%H%M%S)
cp /etc/apt/sources.list "/etc/apt/sources.list.bak.$STAMP" 2>/dev/null || true
cat > /etc/apt/sources.list <<EOF
deb $MIRROR/ $CODENAME main restricted universe multiverse
deb $MIRROR/ $CODENAME-updates main restricted universe multiverse
deb $MIRROR/ $CODENAME-backports main restricted universe multiverse
deb $MIRROR/ $CODENAME-security main restricted universe multiverse
EOF
ok "已写入 $MIRROR（备份: sources.list.bak.$STAMP）"

# -----------------------------------------------------------------------------
log "2/4 apt update"
# -----------------------------------------------------------------------------
apt-get update -qq || die "apt-get update 失败"
ok "软件源可用"

# -----------------------------------------------------------------------------
log "3/4 安装基础工具链"
# -----------------------------------------------------------------------------
PKGS="ca-certificates curl wget git unzip gnupg lsb-release build-essential pkg-config"
MISSING=""
for p in $PKGS; do
  dpkg -s "$p" >/dev/null 2>&1 || MISSING="$MISSING $p"
done

if [ -n "$MISSING" ]; then
  echo "    需要安装:$MISSING"
  apt-get install -y --no-install-recommends $MISSING || die "基础工具安装失败"
else
  echo "    全部已安装"
fi
ok "gcc $(gcc -dumpversion) / make $(make --version | head -1 | awk '{print $3}') / git $(git --version | awk '{print $3}')"

# -----------------------------------------------------------------------------
log "4/4 拉取 bustub 源码"
# -----------------------------------------------------------------------------
REPO=/root/bustub
if [ -d "$REPO/.git" ]; then
  ok "源码已存在: $REPO"
else
  rm -rf "$REPO"
  echo "    git clone https://github.com/cmu-db/bustub.git ..."
  if ! git clone --depth 1 https://github.com/cmu-db/bustub.git "$REPO" 2>&1 | tail -5; then
    die "clone 失败（github.com 可能不稳定，稍后重试）"
  fi
  ok "已克隆到 $REPO"
fi

echo
echo "    分支: $(git -C "$REPO" rev-parse --abbrev-ref HEAD)  commit: $(git -C "$REPO" rev-parse --short HEAD)"
echo "    顶层文件:"
ls -1 "$REPO" | head -20 | sed 's/^/      /'

# 关键文件存在性检查
for f in CMakeLists.txt build_support/packages.sh src test; do
  [ -e "$REPO/$f" ] || die "仓库缺少关键路径: $f"
done
ok "仓库结构完整"

echo
echo "    依赖清单（packages.sh 里声明的包）:"
grep -E '^\s*(packages|PKGS)=' "$REPO/build_support/packages.sh" 2>/dev/null | head -3 | sed 's/^/      /' || echo "      （未能解析）"
