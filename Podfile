# Uncomment the next line to define a global platform for your project
install! 'cocoapods', :warn_for_unused_master_specs_repo => false
platform :ios, '14.0'

target 'GrowthSDK' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks! #:linkage => :static
  
  # 核心依赖（编译时需要，但不会链接进最终 xcframework）
  pod 'CryptoSwift', '1.8.4'
  pod 'Alamofire', '5.10.2'
  
  # 广告 SDK 依赖（编译时需要，但不会链接进最终 xcframework）
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
      
      # # 弱链接配置 - 只对GrowthSDK target生效
      # if target.name == 'GrowthSDK'
      #   config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -weak_framework Alamofire'
      # end
    end
  end
end
