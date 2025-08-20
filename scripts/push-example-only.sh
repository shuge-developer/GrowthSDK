#!/bin/bash

# 仅同步 UnifiedExample/ 到 GitHub SDK 仓库（不构建、不打 tag、不发布 framework）
# 会排除 UnityProject/、Pods/、DerivedData/、xcuserdata、.DS_Store 等大体积/本地缓存目录

set -e

RELEASE_REPO="https://github.com/shuge-developer/GrowthSDK.git"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "📦 准备仅推送示例工程 UnifiedExample/ 到 GitHub..."

if [ ! -d "$PROJECT_DIR/.git" ]; then
  echo "❌ 未检测到 git 仓库，请在 GrowthSDK 项目根目录下执行。"
  exit 1
fi

TEMP_DIR=$(mktemp -d)
echo "📁 临时目录: $TEMP_DIR"

echo "📥 克隆 GitHub 仓库..."
git clone "$RELEASE_REPO" "$TEMP_DIR/release"
cd "$TEMP_DIR/release"
git remote rename origin github 2>/dev/null || true
git checkout main || git checkout -b main

echo "🧹 清理旧的示例目录..."
rm -rf UnifiedExample
mkdir -p UnifiedExample

echo "📋 同步示例工程（排除 UnityProject/、Pods/ 等）..."
rsync -a "$PROJECT_DIR/UnifiedExample/" UnifiedExample/ \
  --delete \
  --exclude 'UnityProject' \
  --exclude 'Pods' \
  --exclude 'DerivedData' \
  --exclude '*.xcuserstate' \
  --exclude 'xcuserdata' \
  --exclude '.DS_Store'

# 提示性 README 附加
if [ -f README.md ]; then
  if ! grep -q "UnifiedExample" README.md 2>/dev/null; then
    echo -e "\n\n---\n\n示例工程：请查看 \`UnifiedExample/\` 目录。首次打开请先进入该目录执行 \`pod install\`。\n注意：仓库默认不包含 \`UnifiedExample/UnityProject\`，请将你本地 Unity 导出的 iOS 工程拷入该目录后，再在每个 App Target 中将 \`UnityFramework.framework\` 设置为 Embed & Sign。" >> README.md
  fi
fi

echo "💾 提交并推送..."
git add UnifiedExample README.md || true
git commit -m "chore(example): sync UnifiedExample only (exclude UnityProject/Pods)" || true
git push github main

echo "✅ 仅示例工程推送完成。仓库: $RELEASE_REPO"


