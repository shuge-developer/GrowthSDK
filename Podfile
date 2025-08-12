# Uncomment the next line to define a global platform for your project
install! 'cocoapods', :warn_for_unused_master_specs_repo => false
platform :ios, '14.0'

target 'GrowthSDK' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks! :linkage => :static
  
  # Pods for GrowthSDK
  pod 'CryptoSwift'
  pod 'Alamofire'
  
  # 开发时使用的广告 SDK（仅用于开发，不会链接进最终 xcframework）
  # 注意：这些依赖仅用于开发时的代码提示和编译，不会链接进最终的 xcframework
  # 在构建 xcframework 时，这些依赖会被排除
  pod 'AppLovinSDK'
  pod 'AppLovinMediationBigoAdsAdapter'
  pod 'AppLovinMediationChartboostAdapter'
  pod 'AppLovinMediationFyberAdapter'
  pod 'AppLovinMediationGoogleAdapter'
  pod 'AppLovinMediationInMobiAdapter'
  pod 'AppLovinMediationVungleAdapter'
  pod 'AppLovinMediationFacebookAdapter'
  pod 'AppLovinMediationMintegralAdapter'
  pod 'AppLovinMediationByteDanceAdapter'
  pod 'AppLovinMediationMolocoAdapter'

end

# 简化的 post_install 钩子
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 设置构建分发
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['SKIP_INSTALL'] = 'NO'
      
      # 统一部署目标版本，解决版本不匹配问题
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
      # 优化 SDK 构建设置
      config.build_settings['DEFINES_MODULE'] = 'YES'
    end
  end
end
