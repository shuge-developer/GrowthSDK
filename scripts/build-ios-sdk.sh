#!/bin/bash

####################################
# Author：Arvin
# Mail: arvinSir.86@gmail.com
# Date：2025/7/10.
####################################

# GrowthSDK XCFramework 构建脚本

# Xcode 配置（重要设置）➤ Build Settings：
# Build Libraries for Distribution > ✅ YES
# Skip Install                     > ❌ NO
# Mach-O Type                      > ✅ Static Library（或 Dynamic Library）
# Defines Module                   > ✅ YES

# 执行脚本提示无权限，请先添加权限:
# chmod +x build-sdk.sh

# 默认值
DEFAULT_CONFIGURATION="Release"
DEFAULT_ARCHIVE_DIR="./tempbuild"
DEFAULT_OUTPUT_DIR="./Frameworks"

# 使用默认值初始化变量
CONFIGURATION="$DEFAULT_CONFIGURATION"
ARCHIVE_DIR="$DEFAULT_ARCHIVE_DIR"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
CLEAN_BUILD=true
VERBOSE=false

# 帮助信息函数
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -c, --config CONFIG     构建配置 (默认: $DEFAULT_CONFIGURATION)
    -a, --archive DIR       临时存档目录 (默认: $DEFAULT_ARCHIVE_DIR)
    -o, --output DIR        输出目录 (默认: $DEFAULT_OUTPUT_DIR)
    --no-clean              不清理之前的构建文件，构建完成后也不清理临时文件
    -v, --verbose           详细构建日志输出
    -h, --help              显示此帮助信息

示例:
    $0
    $0 --output ~/Desktop/SDKs --verbose
    $0 -c Debug --no-clean

说明:
    脚本会自动检测并优先使用 .xcworkspace 文件（CocoaPods 支持）
    如果没有找到 .xcworkspace，则使用 .xcodeproj 文件
    自动处理 CocoaPods 资源复制脚本问题

EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIGURATION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -a|--archive)
            ARCHIVE_DIR="$2"
            shift 2
            ;;
        --no-clean)
            CLEAN_BUILD=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "错误: 未知参数 '$1'"
            echo "使用 '$0 --help' 查看使用帮助"
            exit 1
            ;;
    esac
done

# 获取当前目录作为 SDK 工程路径
SDK_PROJECT_PATH=$(pwd)

# 如果输出目录和存档目录是相对路径，则相对于当前工作目录
if [[ ! "$OUTPUT_DIR" =~ ^/ ]]; then
    OUTPUT_DIR="$(pwd)/$OUTPUT_DIR"
fi

if [[ ! "$ARCHIVE_DIR" =~ ^/ ]]; then
    ARCHIVE_DIR="$(pwd)/$ARCHIVE_DIR"
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 日志记录函数
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    fi
}

# CocoaPods 资源复制脚本清理函数
clean_cocoapods_resources() {
    local project_path="$1"
    
    # 检查是否存在 .xcodeproj 文件
    local xcodeproj_file=""
    for proj in "$project_path"/*.xcodeproj; do
        if [[ -f "$proj/project.pbxproj" ]]; then
            xcodeproj_file="$proj"
            break
        fi
    done
    
    if [[ -z "$xcodeproj_file" ]]; then
        log "未找到 .xcodeproj 文件，跳过资源脚本清理"
        return 0
    fi
    
    log "🛠️  清理 CocoaPods 资源复制脚本..."
    
    # 使用 Ruby 脚本清理 CocoaPods 资源复制脚本
    ruby -e "
require 'xcodeproj'

project_path = '$xcodeproj_file'
begin
  project = Xcodeproj::Project.open(project_path)
  
  removed_count = 0
  project.targets.each do |target|
    phases_to_remove = []
    target.build_phases.each do |phase|
      if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
        if phase.name&.include?('Copy Pods Resources') || 
           phase.name&.include?('[CP] Copy Pods Resources') ||
           phase.shell_script&.include?('Pods-') && phase.shell_script&.include?('-resources.sh')
          phases_to_remove << phase
        end
      end
    end
    
    phases_to_remove.each do |phase|
      puts \"🗑️  移除脚本: #{phase.name}\"
      target.build_phases.delete(phase)
      removed_count += 1
    end
  end
  
  if removed_count > 0
    project.save
    puts \"✅ 已移除 #{removed_count} 个资源复制脚本\"
  else
    puts \"✅ 未发现需要移除的资源复制脚本\"
  end
rescue => e
  puts \"⚠️  清理资源脚本时出错: #{e.message}\"
  puts \"继续构建...\"
end
" 2>/dev/null || log "⚠️  Ruby xcodeproj gem 不可用，跳过资源脚本清理"
}

# 在SDK工程目录中查找项目文件
PROJECT_FILE=""
WORKSPACE_FILE=""
USE_WORKSPACE=false

# 优先查找 .xcworkspace 文件（CocoaPods 支持）
for workspace in *.xcworkspace; do
    if [[ -d "$workspace" ]]; then
        WORKSPACE_FILE="$workspace"
        USE_WORKSPACE=true
        break
    fi
done

# 如果没有找到 workspace，查找 .xcodeproj 文件
if [[ -z "$WORKSPACE_FILE" ]]; then
    for proj in *.xcodeproj; do
        if [[ -f "$proj/project.pbxproj" ]]; then
            PROJECT_FILE="$proj"
            break
        fi
    done
fi

# 验证找到了项目文件
if [[ -z "$WORKSPACE_FILE" && -z "$PROJECT_FILE" ]]; then
    echo "❌ 错误: 在指定路径中找不到 .xcworkspace 或 .xcodeproj 项目文件: $SDK_PROJECT_PATH"
    echo "请确保路径正确且包含有效的Xcode项目"
    exit 1
fi

# 确定SDK名称和构建参数
if [[ "$USE_WORKSPACE" == true ]]; then
    SDK_NAME="${WORKSPACE_FILE%.xcworkspace}"
    BUILD_PARAM="-workspace"
    BUILD_FILE="$WORKSPACE_FILE"
    log "📦 检测到 CocoaPods 工作区: $WORKSPACE_FILE"
    
    # 检查是否有 Podfile，如果有则更新依赖
    if [[ -f "Podfile" ]]; then
        echo "📦 检测到 CocoaPods 依赖，更新 Pods..."
        if command -v pod >/dev/null 2>&1; then
            if [[ "$VERBOSE" == true ]]; then
                pod install --repo-update
            else
                pod install --repo-update --silent
            fi
        else
            echo "⚠️  未找到 pod 命令，跳过依赖更新"
        fi
    fi
else
    SDK_NAME="${PROJECT_FILE%.xcodeproj}"
    BUILD_PARAM="-project"
    BUILD_FILE="$PROJECT_FILE"
    log "📁 使用项目文件: $PROJECT_FILE"
fi

OUTPUT_XCFRAMEWORK="$OUTPUT_DIR/${SDK_NAME}.xcframework"

echo "🚀 开始构建 $SDK_NAME XCFramework"
echo "📋 配置信息:"
echo "   - SDK工程路径: $SDK_PROJECT_PATH"
echo "   - SDK名称: $SDK_NAME"
echo "   - 构建配置: $CONFIGURATION"
echo "   - 使用工作区: $USE_WORKSPACE"
echo "   - 构建文件: $BUILD_FILE"
echo "   - 临时目录: $ARCHIVE_DIR"
echo "   - 输出目录: $OUTPUT_DIR"
echo "   - 输出文件: $OUTPUT_XCFRAMEWORK"
echo ""

# 如果需要，清理之前的存档和输出文件
if [[ "$CLEAN_BUILD" == true ]]; then
    echo "🧹 清理之前的构建文件..."
    rm -rf "$ARCHIVE_DIR" "$OUTPUT_XCFRAMEWORK"
    log "已清理: $ARCHIVE_DIR 和 $OUTPUT_XCFRAMEWORK"
fi

# 创建存档目录
mkdir -p "$ARCHIVE_DIR"

# 构建前清理 CocoaPods 资源复制脚本
if [[ "$USE_WORKSPACE" == true ]]; then
    clean_cocoapods_resources "$SDK_PROJECT_PATH"
fi

# 为iOS设备构建
echo "📱 构建 iOS 设备版本..."
log "开始构建 iOS 设备架构"

if [[ "$USE_WORKSPACE" == true ]]; then
    # 使用 workspace 和 destination（CocoaPods 兼容）
    BUILD_CMD="xcodebuild archive \
        $BUILD_PARAM \"$BUILD_FILE\" \
        -scheme \"$SDK_NAME\" \
        -configuration \"$CONFIGURATION\" \
        -destination \"generic/platform=iOS\" \
        -archivePath \"$ARCHIVE_DIR/ios_devices.xcarchive\" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        DEFINES_MODULE=YES \
        SWIFT_INSTALL_OBJC_HEADER=YES \
        SWIFT_OBJC_INTERFACE_HEADER_NAME=\"${SDK_NAME}-Swift.h\""
else
    # 使用传统的 project 和 sdk 参数
    BUILD_CMD="xcodebuild archive \
        $BUILD_PARAM \"$BUILD_FILE\" \
        -scheme \"$SDK_NAME\" \
        -sdk iphoneos \
        -configuration \"$CONFIGURATION\" \
        -archivePath \"$ARCHIVE_DIR/ios_devices.xcarchive\" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        DEFINES_MODULE=YES \
        SWIFT_INSTALL_OBJC_HEADER=YES \
        SWIFT_OBJC_INTERFACE_HEADER_NAME=\"${SDK_NAME}-Swift.h\""
fi

if [[ "$VERBOSE" == false ]]; then
    BUILD_CMD="$BUILD_CMD -quiet"
fi

# 再次清理资源脚本（防止 pod install 重新生成）
if [[ "$USE_WORKSPACE" == true ]]; then
    clean_cocoapods_resources "$SDK_PROJECT_PATH"
fi

if ! eval "$BUILD_CMD"; then
    echo "❌ iOS 设备版本构建失败"
    exit 1
fi

echo "✅ iOS 设备版本构建完成"

# 为iOS模拟器构建
echo "🖥️  构建 iOS 模拟器版本..."
log "开始构建 iOS 模拟器架构"

if [[ "$USE_WORKSPACE" == true ]]; then
    # 使用 workspace 和 destination（CocoaPods 兼容）
    BUILD_CMD="xcodebuild archive \
        $BUILD_PARAM \"$BUILD_FILE\" \
        -scheme \"$SDK_NAME\" \
        -configuration \"$CONFIGURATION\" \
        -destination \"generic/platform=iOS Simulator\" \
        -archivePath \"$ARCHIVE_DIR/ios_simulator.xcarchive\" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        DEFINES_MODULE=YES \
        SWIFT_INSTALL_OBJC_HEADER=YES \
        SWIFT_OBJC_INTERFACE_HEADER_NAME=\"${SDK_NAME}-Swift.h\""
else
    # 使用传统的 project 和 sdk 参数
    BUILD_CMD="xcodebuild archive \
        $BUILD_PARAM \"$BUILD_FILE\" \
        -scheme \"$SDK_NAME\" \
        -sdk iphonesimulator \
        -configuration \"$CONFIGURATION\" \
        -archivePath \"$ARCHIVE_DIR/ios_simulator.xcarchive\" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        DEFINES_MODULE=YES \
        SWIFT_INSTALL_OBJC_HEADER=YES \
        SWIFT_OBJC_INTERFACE_HEADER_NAME=\"${SDK_NAME}-Swift.h\""
fi

if [[ "$VERBOSE" == false ]]; then
    BUILD_CMD="$BUILD_CMD -quiet"
fi

# 再次清理资源脚本
if [[ "$USE_WORKSPACE" == true ]]; then
    clean_cocoapods_resources "$SDK_PROJECT_PATH"
fi

if ! eval "$BUILD_CMD"; then
    echo "❌ iOS 模拟器版本构建失败"
    exit 1
fi

echo "✅ iOS 模拟器版本构建完成"

# 创建XCFramework
echo "📦 创建 XCFramework..."
log "开始合并为 XCFramework"

if [[ "$VERBOSE" == true ]]; then
    xcodebuild -create-xcframework \
        -framework "$ARCHIVE_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework" \
        -framework "$ARCHIVE_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework" \
        -output "$OUTPUT_XCFRAMEWORK"
else
    xcodebuild -create-xcframework \
        -framework "$ARCHIVE_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework" \
        -framework "$ARCHIVE_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework" \
        -output "$OUTPUT_XCFRAMEWORK" > /dev/null 2>&1
fi

# 删除 xcframework 目录下的所有 markdown 文件
find "$OUTPUT_XCFRAMEWORK" -name "*.md" -delete

if [[ $? -ne 0 ]]; then
    echo "❌ XCFramework 创建失败"
    echo "检查路径:"
    echo "   iOS 设备: $ARCHIVE_DIR/ios_devices.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework"
    echo "   iOS 模拟器: $ARCHIVE_DIR/ios_simulator.xcarchive/Products/Library/Frameworks/${SDK_NAME}.framework"
    exit 1
fi

# 验证输出结果
if [[ ! -d "$OUTPUT_XCFRAMEWORK" ]]; then
    echo "❌ XCFramework 创建失败: 输出文件不存在"
    exit 1
fi

echo ""
echo "🎉 构建完成！"
echo "📍 XCFramework 位置: $OUTPUT_XCFRAMEWORK"

# 显示框架信息
if command -v file >/dev/null 2>&1; then
    echo ""
    echo "📊 框架信息:"
    echo "   - 大小: $(du -h "$OUTPUT_XCFRAMEWORK" | cut -f1 | head -1)"
    if [[ "$VERBOSE" == true ]]; then
        echo "   - 支持的平台:"
        find "$OUTPUT_XCFRAMEWORK" -name "*.framework" -type d | while read -r framework; do
            platform=$(basename "$(dirname "$framework")")
            echo "     * $platform"
        done
        
        # 显示架构信息
        echo "   - 架构信息:"
        find "$OUTPUT_XCFRAMEWORK" -name "${SDK_NAME}.framework" -type d | while read -r framework; do
            if [[ -f "$framework/$SDK_NAME" ]]; then
                echo "     * $(basename "$(dirname "$framework")"): $(file "$framework/$SDK_NAME" | cut -d: -f2-)"
            fi
        done
    fi
fi

# 自动清理临时构建文件
if [[ "$CLEAN_BUILD" == true ]]; then
    echo ""
    echo "🧹 自动清理临时构建文件..."
    rm -rf "$ARCHIVE_DIR"
    echo "✅ 临时文件已清理"
else
    echo ""
    echo "📁 临时构建文件保留在: $ARCHIVE_DIR"
    echo "   如需清理，请手动删除该目录"
fi

echo ""
echo "✨ 全部完成! 您可以将 $OUTPUT_XCFRAMEWORK 集成到其他项目中了。"
echo ""
if [[ "$USE_WORKSPACE" == true ]]; then
    echo "📝 CocoaPods 集成说明:"
    echo "   - 该 XCFramework 已包含所有 CocoaPods 依赖"
    echo "   - 可以直接在其他项目中使用，无需额外的 CocoaPods 配置"
    echo "   - 建议在目标项目中使用静态库链接方式"
fi
