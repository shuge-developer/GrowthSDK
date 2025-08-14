# Uncomment the next line to define a global platform for your project
install! 'cocoapods', :warn_for_unused_master_specs_repo => false
platform :ios, '14.0'

target 'GrowthSDK' do
  # 强制所有依赖作为静态库链接
  use_frameworks! :linkage => :static
  
  # 核心依赖（编译时需要，但不会链接进最终 xcframework）
  pod 'CryptoSwift', '1.8.4'
  # pod 'Alamofire', '5.10.2'  # Removed - using URLSession instead
  
  # 广告 SDK 依赖已移除 - 将由下游应用提供
  # pod 'AppLovinSDK', '13.3.1'
  # pod 'AppLovinMediationBigoAdsAdapter'
  # pod 'AppLovinMediationChartboostAdapter'
  # pod 'AppLovinMediationFyberAdapter'
  # pod 'AppLovinMediationGoogleAdapter'
  # pod 'AppLovinMediationInMobiAdapter'
  # pod 'AppLovinMediationVungleAdapter'
  # pod 'AppLovinMediationFacebookAdapter'
  # pod 'AppLovinMediationMintegralAdapter'
  # pod 'AppLovinMediationByteDanceAdapter'
  # pod 'AppLovinMediationMolocoAdapter'

end

# 简化的 post_install 钩子
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 设置构建分发 (对于静态库不是必需的，但保留也无妨)
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      
      # 统一部署目标版本，解决版本不匹配问题
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
      # 优化 SDK 构建设置
      config.build_settings['DEFINES_MODULE'] = 'YES'
    end
  end
end
