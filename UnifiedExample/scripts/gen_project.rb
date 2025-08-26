#!/usr/bin/env ruby
# 生成一个包含三种 Demo 的多 target Xcode 工程，并统一引入 Unity 子工程

require 'xcodeproj'
require 'fileutils'

ROOT = File.expand_path(File.join(__dir__, '..'))
PROJECT_PATH = File.join(ROOT, 'UnifiedExample.xcodeproj')
UNITY_PATH = File.join(ROOT, 'UnityProject')

OBJ_SRC = File.join(ROOT, 'ObjcExample')
SWIFT_SRC = File.join(ROOT, 'SwiftExample')
SWIFTUI_SRC = File.join(ROOT, 'SwiftUIExample')

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)

# 基础配置
project.build_configuration_list.set_setting('IPHONEOS_DEPLOYMENT_TARGET', '14.0')
project.build_configuration_list.set_setting('SWIFT_VERSION', '5.0')

# 创建三个 targets
app_targets = []
[
  ['ObjcExample', :objc, OBJ_SRC],
  ['SwiftExample', :swift, SWIFT_SRC],
  ['SwiftUIExample', :swift, SWIFTUI_SRC]
].each do |name, lang, src_path|
  target = project.new_target(:application, name, :ios, '14.0')
  target.build_configuration_list.set_setting('PRODUCT_BUNDLE_IDENTIFIER', "com.shuge.unified.#{name.downcase}")
  target.build_configuration_list.set_setting('INFOPLIST_FILE', "#{name}/Info.plist")
  target.build_configuration_list.set_setting('ENABLE_BITCODE', 'NO')
  target.build_configuration_list.set_setting('LD_RUNPATH_SEARCH_PATHS', '$(inherited) @executable_path/Frameworks')
  target.build_configuration_list.set_setting('OTHER_LDFLAGS', '$(inherited) -ObjC')

  # 源码分组（group 路径指向子目录 name，fileRef 需使用相对 src 目录的相对路径，避免重复目录）
  group = project.new_group(name, name)
  
  # 添加源文件
  Dir.glob(File.join(src_path, '**/*.{m,mm,h,swift}')).each do |path|
    rel_path_in_group = path.sub(/^#{Regexp.escape(src_path)}\//, '')
    file_ref = group.new_reference(rel_path_in_group)
    target.add_file_references([file_ref])
  end
  
  # 添加资源文件
  Dir.glob(File.join(src_path, '**/*.{storyboard,xib,xcassets,plist}')).each do |path|
    rel_path_in_group = path.sub(/^#{Regexp.escape(src_path)}\//, '')
    file_ref = group.new_reference(rel_path_in_group)
    if path.end_with?('.plist') && File.basename(path) != 'Info.plist'
      target.resources_build_phase.add_file_reference(file_ref)
    elsif !path.end_with?('.plist')
      target.resources_build_phase.add_file_reference(file_ref)
    end
  end
  
  # 添加图片资源
  Dir.glob(File.join(src_path, '**/*.{png,jpg,jpeg,gif}')).each do |path|
    rel_path_in_group = path.sub(/^#{Regexp.escape(src_path)}\//, '')
    file_ref = group.new_reference(rel_path_in_group)
    target.resources_build_phase.add_file_reference(file_ref)
  end
  
  app_targets << target
end

# 暂不引入 Unity 子工程，先确保 Xcode 可稳定打开工程

# 规范化系统框架引用，避免写死到具体 iPhoneOSXX.X.sdk 路径导致 Xcode 解析崩溃
project.files.each do |file|
  path = file.path
  next unless path.is_a?(String)
  if file.source_tree == 'DEVELOPER_DIR' && path.include?('Platforms/iPhoneOS.platform/Developer/SDKs')
    if path.include?('System/Library/Frameworks/') && path.end_with?('.framework')
      framework_name = File.basename(path)
      file.path = File.join('System/Library/Frameworks', framework_name)
      file.source_tree = 'SDKROOT'
    end
  end
end

project.save
puts "Generated: #{PROJECT_PATH}"
puts "Note: Please manually add UnityFramework.framework to each target's Frameworks, Libraries, and Embedded Content section in Xcode"
