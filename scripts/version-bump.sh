#!/bin/bash

set -e

# 版本迭代与同步工具
# - 读取当前版本（podspec 优先，其次 Xcode MARKETING_VERSION）
# - 支持按 patch/minor/major 递增
# - 支持直接设置指定版本
# - 支持只打印或写回到 podspec 与 Xcode 工程

PROJECT_DIR="$(pwd)"
MODE="print"          # print | apply
BUMP_TYPE="patch"      # patch | minor | major
SET_VERSION=""        # 显式设置版本

usage() {
    echo "用法: $0 [--project-dir <dir>] [--apply|--print] [--bump <patch|minor|major>] [--set <x.y.z>]"
    echo "示例:"
    echo "  - 仅打印下一个补丁版本: $0 --print --bump patch"
    echo "  - 应用小版本递增并写回: $0 --apply --bump minor"
    echo "  - 直接设置版本并写回:   $0 --apply --set 1.2.3"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project-dir)
            PROJECT_DIR="$2"; shift 2 ;;
        --apply)
            MODE="apply"; shift ;;
        --print)
            MODE="print"; shift ;;
        --bump)
            BUMP_TYPE="$2"; shift 2 ;;
        --set)
            SET_VERSION="$2"; shift 2 ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            echo "❌ 未知参数: $1"; usage; exit 1 ;;
    esac
done

get_current_version_from_podspec() {
    local podspec="$PROJECT_DIR/GrowthSDK.podspec"
    if [[ -f "$podspec" ]]; then
        local v
        v=$(grep -E "s.version\s*=\s*'[^']+'" "$podspec" | sed -E "s/.*'([^']+)'.*/\\1/")
        if [[ -n "$v" ]]; then echo "$v"; return 0; fi
    fi
    return 1
}

get_current_marketing_version() {
    local pbxproj="$PROJECT_DIR/GrowthSDK.xcodeproj/project.pbxproj"
    if [[ -f "$pbxproj" ]]; then
        local v
        v=$(grep -E "MARKETING_VERSION = [0-9]+(\\.[0-9]+){0,2}" "$pbxproj" | head -1 | sed -E "s/.*MARKETING_VERSION = ([^;]+).*/\\1/")
        if [[ -n "$v" ]]; then echo "$v"; return 0; fi
    fi
    return 1
}

parse_version() {
    local ver="$1"
    IFS='.' read -r major minor patch <<< "${ver}"
    major=${major:-0}; minor=${minor:-0}; patch=${patch:-0}
    echo "$major" "$minor" "$patch"
}

bump_version() {
    local ver="$1"; local type="$2"
    read -r major minor patch < <(parse_version "$ver")
    case "$type" in
        major)
            major=$((major+1)); minor=0; patch=0 ;;
        minor)
            minor=$((minor+1)); patch=0
            if [[ $minor -gt 9 ]]; then minor=0; major=$((major+1)); fi ;;
        patch|*)
            patch=$((patch+1))
            if [[ $patch -gt 9 ]]; then patch=0; minor=$((minor+1)); fi
            if [[ $minor -gt 9 ]]; then minor=0; major=$((major+1)); fi ;;
    esac
    echo "${major}.${minor}.${patch}"
}

resolve_current_version() {
    local current
    if current=$(get_current_version_from_podspec); then
        echo "$current"; return 0
    elif current=$(get_current_marketing_version); then
        echo "$current"; return 0
    fi
    echo "1.0.0"
}

apply_version() {
    local version="$1"
    local podspec="$PROJECT_DIR/GrowthSDK.podspec"
    local pbxproj="$PROJECT_DIR/GrowthSDK.xcodeproj/project.pbxproj"

    if [[ -f "$podspec" ]]; then
        sed -i '' "s/s.version.*=.*'.*'/s.version          = '$version'/" "$podspec"
    fi
    if [[ -f "$pbxproj" ]]; then
        sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $version/" "$pbxproj"
    fi
}

main() {
    local current next
    if [[ -n "$SET_VERSION" ]]; then
        next="$SET_VERSION"
    else
        current=$(resolve_current_version)
        next=$(bump_version "$current" "$BUMP_TYPE")
    fi

    if [[ "$MODE" == "apply" ]]; then
        apply_version "$next"
    fi

    echo "$next"
}

main "$@"


