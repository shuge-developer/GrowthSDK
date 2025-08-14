#!/bin/bash

# GrowthSDK 构建和发布脚本
# 源代码提交到阿里云，打包文件提交到 GitHub

set -e

# 配置
VERSION=${1:-"1.0.0"}
SOURCE_REPO="git@codeup.aliyun.com:630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK.git"
RELEASE_REPO="https://github.com/shuge-developer/GrowthSDK.git"

echo "🚀 开始构建和发布 GrowthSDK v$VERSION"

# 检查参数
if [ -z "$VERSION" ]; then
    echo "❌ 请提供版本号: ./build-and-release.sh <version>"
    exit 1
fi

# 检查当前是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 git 仓库"
    exit 1
fi

# 检查远程仓库配置
echo "📋 检查远程仓库配置..."
if ! git remote get-url origin | grep -q "codeup.aliyun.com"; then
    echo "❌ 当前仓库不是阿里云仓库，请确保在正确的源代码仓库中"
    exit 1
fi

# 添加 GitHub 远程仓库（如果不存在）
if ! git remote get-url github 2>/dev/null; then
    echo "➕ 添加 GitHub 远程仓库..."
    git remote add github $RELEASE_REPO
else
    echo "✅ GitHub 远程仓库已存在"
fi

# 确保在 main 分支
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  当前不在 main 分支，正在切换到 main 分支..."
    git checkout main
fi

# 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 使用专业的 SDK 构建脚本
echo "🔨 使用专业 SDK 构建脚本..."
if ! ./scripts/build-ios-sdk.sh --verbose; then
    echo "❌ SDK 构建失败"
    exit 1
fi

# 更新 podspec 版本
echo "📝 更新 podspec 版本..."
sed -i '' "s/s.version.*=.*'.*'/s.version          = '$VERSION'/" GrowthSDK.podspec

# 提交源代码到阿里云仓库（不包含 framework）
echo "💾 提交源代码到阿里云仓库..."
git add GrowthSDK/ GrowthSDK.xcodeproj/ GrowthSDK.xcworkspace/ Podfile Podfile.lock scripts/ || true
git commit -m "feat: update source code for v$VERSION" || true
git push origin main

# 创建临时目录用于发布
TEMP_DIR=$(mktemp -d)
echo "📁 创建临时目录: $TEMP_DIR"

# 克隆或更新 GitHub 仓库
echo "📥 准备 GitHub 发布仓库..."
if [ -d "$TEMP_DIR/release" ]; then
    cd "$TEMP_DIR/release"
    git pull github main
else
    git clone $RELEASE_REPO "$TEMP_DIR/release"
    cd "$TEMP_DIR/release"
    # 确保远程仓库名称正确
    git remote rename origin github 2>/dev/null || true
fi

# 清理 GitHub 仓库，只保留必要文件
echo "🧹 清理 GitHub 仓库..."
git rm -rf * || true

# 复制发布文件到 GitHub 仓库
echo "📋 复制发布文件到 GitHub 仓库..."
cp -R /Users/arvin/Desktop/ShuGeProjects/SourceCode/FrameWorks/SDK/GrowthSDK/Frameworks ./
cp /Users/arvin/Desktop/ShuGeProjects/SourceCode/FrameWorks/SDK/GrowthSDK/GrowthSDK.podspec ./

# 创建 README 文件
echo "📝 创建 README 文件..."
cat > README.md << 'EOF'
# GrowthSDK

GrowthSDK 是一个用于 iOS 应用开发的 SDK 框架。

## 安装

### CocoaPods

在您的 `Podfile` 中添加：

```ruby
pod 'GrowthSDK', '~> 1.0.0'
```

然后运行：

```bash
pod install
```

## 版本历史

请查看 [Releases](https://github.com/shuge-developer/GrowthSDK/releases) 页面了解版本更新历史。

## 许可证

版权所有 © 2024 Shuge Developer
EOF

# 提交到 GitHub 仓库
echo "💾 提交到 GitHub 仓库..."
git add .
git commit -m "release: v$VERSION"
git push github main

# 创建版本标签
echo "🏷️  创建版本标签..."
git tag "v$VERSION"
git push github "v$VERSION"

# 清理临时目录
rm -rf "$TEMP_DIR"

echo ""
echo "✅ 发布完成！"
echo "📝 源代码已提交到阿里云仓库"
echo "📦 Framework 已推送到 GitHub 仓库"
echo "🏷️  版本标签: v$VERSION"
echo "📋 下游集成方式:"
echo "pod 'GrowthSDK', '~> $VERSION'"
echo ""
echo "🔗 发布仓库地址: $RELEASE_REPO"
echo "📝 源代码仓库地址: $SOURCE_REPO"
