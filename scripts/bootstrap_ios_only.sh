#!/usr/bin/env bash
# 仅为当前工程生成 iOS 平台目录（不生成 Android），并写入相册等隐私说明。
# 若本机未安装 Flutter，可使用 Docker：`docker pull ghcr.io/cirruslabs/flutter:stable`
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

IMAGE="${FLUTTER_DOCKER_IMAGE:-ghcr.io/cirruslabs/flutter:stable}"

flutter_create_ios() {
  if [[ -d ios ]]; then
    echo "ios/ 已存在，跳过 flutter create。"
    return 0
  fi
  if command -v flutter >/dev/null 2>&1; then
    flutter create . --platforms=ios --project-name livewall_ai
  elif docker info >/dev/null 2>&1; then
    docker run --rm \
      -v "$ROOT:/app" \
      -w /app \
      "$IMAGE" \
      flutter create . --platforms=ios --project-name livewall_ai
  else
    echo "error: 未找到 flutter，且 Docker 不可用。请安装 Flutter SDK，或启动 Docker 后重试。" >&2
    exit 1
  fi
}

flutter_create_ios
python3 "$ROOT/scripts/patch_ios_info_plist.py" "$ROOT/ios/Runner/Info.plist"

echo "完成。请在 Mac 上安装 CocoaPods 后执行：cd ios && pod install"
echo "然后打开 ios/Runner.xcworkspace（勿打开 .xcodeproj）。若尚未安装 pod：brew install cocoapods 或 sudo gem install cocoapods"
