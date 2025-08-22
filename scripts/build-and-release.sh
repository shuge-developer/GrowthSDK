#!/bin/bash

# GrowthSDK 构建和发布脚本
# 源代码提交到阿里云，打包文件 + 示例工程提交到 GitHub

set -e

# 配置
SOURCE_REPO="git@codeup.aliyun.com:630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK.git"
RELEASE_REPO="https://github.com/shuge-developer/GrowthSDK.git"
PROJECT_DIR="$(pwd)"
VERSION=""
BUMP_TYPE="patch"   # 可选：patch | minor | major
ONLY_BUMP=false      # 仅更新版本号并退出
DOCS_ONLY=false      # 仅推送文档（README + Wiki）到发布仓库

# 打印使用方法
usage() {
    cat << EOF
用法: $(basename "$0") [<version>] [--bump <patch|minor|major>] [--only-bump] [--docs-only] [--help]

说明:
  - 本脚本用于一键完成 GrowthSDK 的版本迭代、构建 XCFramework、
    提交源代码到阿里云仓库，以及将产物发布到 GitHub 并打标签。

选项:
  <version>              显式指定要发布的版本号（例如: 1.2.3）。
  --bump, -b <type>      自动迭代版本号，<type> 可选:
                         - patch (默认): x.y.z -> x.y.(z+1)，按 9 进位
                         - minor         : x.y.z -> x.(y+1).0，按 9 进位
                         - major         : x.y.z -> (x+1).0.0
  --only-bump            仅更新版本号（同步写入 podspec 与 MARKETING_VERSION）后立即退出，
                         不执行后续的构建与推送流程。
  --docs-only            仅推送文档（README.md 与 Wiki/）到 GitHub 发布仓库，不构建 SDK、
                         不打 tag、不中断/校验阿里云 origin。
  -h, --help             显示此帮助信息。

常见用法:
  1) 自动补丁位迭代并完整发布（默认）
     $(basename "$0")

  2) 自动小版本迭代并完整发布
     $(basename "$0") --bump minor

  3) 自动大版本迭代并完整发布
     $(basename "$0") --bump major

  4) 指定具体版本并完整发布
     $(basename "$0") 1.3.0

  5) 仅更新版本号并退出（用于验证版本写入是否正确）
     $(basename "$0") --only-bump --bump patch
     或
     $(basename "$0") --only-bump 1.2.3

  6) 仅推送文档（不构建二进制、不打标签）
     $(basename "$0") --docs-only

流程概览:
  - 解析/计算版本号（调用 scripts/version-bump.sh）
  - 写入版本到 GrowthSDK.podspec 与 Xcode MARKETING_VERSION
  - 调用 scripts/build-ios-sdk.sh 构建 XCFramework 到 ./Frameworks
  - 提交源代码到阿里云 origin/main
  - 将 Frameworks + podspec + README 推送到 GitHub 仓库 main，并创建 tag v<version>

前置要求:
  - 当前目录为 GrowthSDK 工程根目录，且为 git 仓库
  - origin 指向阿里云源码仓库，github 远程指向 GitHub 发布仓库
  - 已安装 Xcode 命令行工具（xcodebuild）和 CocoaPods（可选）

示例输出:
  成功后会显示版本号、GitHub 推送信息以及 CocoaPods 集成提示。

EOF
}

# 解析参数（支持位置参数版本号与 --bump / --docs-only）
while [[ $# -gt 0 ]]; do
    case "$1" in
        --bump|-b)
            BUMP_TYPE="$2"; shift 2 ;;
        --only-bump)
            ONLY_BUMP=true; shift ;;
        --docs-only)
            DOCS_ONLY=true; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"; shift
            else
                echo "❌ 未知参数: $1"; usage; exit 1
            fi
            ;;
    esac
done

# docs-only 模式不需要版本号；否则计算版本号
if [[ "$DOCS_ONLY" != true ]]; then
    if [[ -z "$VERSION" ]]; then
        VERSION=$(./scripts/version-bump.sh --print --bump "$BUMP_TYPE")
    fi
    echo "🚀 开始构建和发布 GrowthSDK v$VERSION  (bump: $BUMP_TYPE)"
else
    echo "📝 进入仅文档发布模式（README + Wiki）"
fi

# 仅更新版本并提前退出
if [[ "$ONLY_BUMP" == true ]]; then
    echo "📝 仅更新版本号到 $VERSION..."
    ./scripts/version-bump.sh --apply --set "$VERSION"
    echo "✅ 版本号已更新为 $VERSION，按要求提前结束。"
    exit 0
fi

# 无需检查必填参数，已支持自动递增

# 检查当前是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 git 仓库"
    exit 1
fi

# 非 docs-only 才校验阿里云源仓
if [[ "$DOCS_ONLY" != true ]]; then
  echo "📋 检查远程仓库配置..."
  if ! git remote get-url origin | grep -q "codeup.aliyun.com"; then
      echo "❌ 当前仓库不是阿里云仓库，请确保在正确的源代码仓库中"
      exit 1
  fi
fi

# 添加 GitHub 远程仓库（如果不存在）
if ! git remote get-url github 2>/dev/null; then
    echo "➕ 添加 GitHub 远程仓库..."
    git remote add github $RELEASE_REPO
else
    echo "✅ GitHub 远程仓库已存在"
fi

# 确保在 main 分支（docs-only 也建议在 main）
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  当前不在 main 分支，正在切换到 main 分支..."
    git checkout main
fi

# 拉取最新代码
echo "📥 拉取最新代码..."
git pull origin main

# 非 docs-only：在构建前同步更新版本号（podspec 与 Xcode MARKETING_VERSION）
if [[ "$DOCS_ONLY" != true ]]; then
  echo "📝 更新版本号到 $VERSION..."
  ./scripts/version-bump.sh --apply --set "$VERSION"
fi

# 非 docs-only：构建 SDK
if [[ "$DOCS_ONLY" != true ]]; then
  echo "🔨 使用专业 SDK 构建脚本..."
  if ! ./scripts/build-ios-sdk.sh --verbose; then
      echo "❌ SDK 构建失败"
      exit 1
  fi
fi

# 版本已在构建前更新，无需再次修改 podspec

# 非 docs-only：提交源代码到阿里云仓库（不包含 framework）
if [[ "$DOCS_ONLY" != true ]]; then
  echo "💾 提交源代码到阿里云仓库..."
  git add GrowthSDK/ GrowthSDK.xcodeproj/ GrowthSDK.xcworkspace/ Podfile Podfile.lock scripts/ UnifiedExample/ || true
  git commit -m "feat: update source code for v$VERSION" || true
  git push origin main
fi

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

# 清理 GitHub 仓库
if [[ "$DOCS_ONLY" != true ]]; then
  echo "🧹 清理 GitHub 仓库..."
  git rm -rf * || true
else
  echo "🧹（跳过）docs-only 模式不清空仓库"
fi

# 复制发布文件到 GitHub 仓库
echo "📋 复制发布文件到 GitHub 仓库..."
if [[ "$DOCS_ONLY" != true ]]; then
  cp -R "$PROJECT_DIR/Frameworks" ./
  cp "$PROJECT_DIR/GrowthSDK.podspec" ./
  # 强制添加 Frameworks 目录（即使被 .gitignore 忽略）
  git add -f Frameworks/
fi
cp "$PROJECT_DIR/README.md" ./
if [ -d "$PROJECT_DIR/Wiki" ]; then
  rsync -a "$PROJECT_DIR/Wiki" ./ --delete
fi

# 同步发布 UnifiedExample 集成示例（排除体积/本地化生成文件）
EXAMPLE_SRC="$PROJECT_DIR/UnifiedExample"
if [ -d "$EXAMPLE_SRC" ]; then
  echo "📦 同步发布示例工程 UnifiedExample/ ..."
  mkdir -p UnifiedExample
  rsync -a "$EXAMPLE_SRC"/ UnifiedExample/ \
    --delete \
    --exclude 'Pods' \
    --exclude 'DerivedData' \
    --exclude 'UnityProject' \
    --exclude '*.xcuserstate' \
    --exclude 'xcuserdata' \
    --exclude '.DS_Store'
  # 在 README 中追加一句指引（若仓库根 README 存在）
  if grep -q "UnifiedExample" README.md 2>/dev/null; then :; else
    echo "\n\n---\n\n示例工程：请查看 \`UnifiedExample/\` 目录，首次打开先执行 \`pod install\`。" >> README.md
  fi
else
  echo "⚠️  未找到示例工程目录：$EXAMPLE_SRC，跳过示例同步。"
fi

# 提交到 GitHub 仓库
echo "💾 提交到 GitHub 仓库..."
git add .
if [[ "$DOCS_ONLY" != true ]]; then
  git commit -m "release: v$VERSION"
else
  git commit -m "docs: update README & Wiki"
fi
git push github main

# 非 docs-only：创建版本标签
if [[ "$DOCS_ONLY" != true ]]; then
  echo "🏷️  创建版本标签..."
  git tag "v$VERSION"
  git push github "v$VERSION"
else
  echo "🏷️  跳过打标签（docs-only 模式）"
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

echo ""
echo "✅ 发布完成！"
if [[ "$DOCS_ONLY" != true ]]; then
  echo "📝 源代码已提交到阿里云仓库"
  echo "📦 Framework 与示例工程已推送到 GitHub 仓库"
  echo "🏷️  版本标签: v$VERSION"
  echo "📋 下游集成方式:"
  echo "pod 'GrowthSDK', '~> $VERSION'"
else
  echo "📝 文档（README + Wiki）已推送到 GitHub 仓库"
fi
echo ""
echo "🔗 发布仓库地址: $RELEASE_REPO"
echo "📝 源代码仓库地址: $SOURCE_REPO"
