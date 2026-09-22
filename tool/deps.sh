#!/usr/bin/env bash
# 依赖拉取入口：优先走原始仓库（GitHub），原始地址不可达时自动回退到 mirror（Gitee）。
#
# pubspec.yaml 里始终写原始地址，mirror 只在传输层通过仓库级 git 规则
# url.<mirror>.insteadOf 生效，因此不会改动任何入库文件。
#
# 用法：tool/deps.sh [pub 子命令与参数...]，默认 `get`。
#   tool/deps.sh            # flutter pub get
#   tool/deps.sh upgrade    # flutter pub upgrade

set -euo pipefail

ORIGIN_URL="https://github.com/Fi2zz/conatus.git"
MIRROR_URL="https://gitee.com/fitzy/conatus.git"
PROBE_TIMEOUT=8

# insteadOf 用去掉 .git 的裸前缀，可同时覆盖带 / 不带 .git 的写法
ORIGIN_PREFIX="${ORIGIN_URL%.git}"
CONFIG_KEY="url.${MIRROR_URL}.insteadOf"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# 探测 git smart-http 端点是否可用（-f 使 4xx/5xx 视为失败）
origin_reachable() {
  curl -fsS -o /dev/null --max-time "$PROBE_TIMEOUT" \
    "${ORIGIN_URL%/}/info/refs?service=git-upload-pack"
}

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "警告：当前目录不是 git 仓库，无法写入 mirror 回退规则" >&2
  exec flutter pub "${1:-get}"
fi

if origin_reachable; then
  echo "原始仓库可达，使用 ${ORIGIN_URL}"
  git config --local --unset-all "$CONFIG_KEY" 2>/dev/null || true
else
  echo "原始仓库不可达，回退到 mirror ${MIRROR_URL}"
  git config --local --add "$CONFIG_KEY" "$ORIGIN_PREFIX"
fi

if [ $# -eq 0 ]; then
  set -- get
fi
exec flutter pub "$@"