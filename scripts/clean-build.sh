#!/bin/bash

# GrowthSDK 清理构建脚本
# 用于日常开发时清理构建产物

set -e

echo "🧹 开始清理 GrowthSDK 构建产物..."

# 清理 Xcode 构建产物
echo "📦 清理 Xcode 构建产物..."
rm -rf build/
rm -rf DerivedData/

# 清理 Frameworks 目录
echo "📁 清理 Frameworks 目录..."
rm -rf Frameworks/

# 清理 Pods 构建产物
echo "📦 清理 Pods 构建产物..."
rm -rf Pods/build/

# 清理 Xcode 缓存
echo "🗑️  清理 Xcode 缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/GrowthSDK-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/ModuleCache.noindex/

echo "✅ 清理完成！"
echo ""
echo "💡 提示："
echo "- Frameworks 目录已被添加到 .gitignore，不会提交到源代码仓库"
echo "- 构建产物只会在发布时推送到 GitHub 仓库"
echo "- 日常开发时不会看到构建产物的变更"
