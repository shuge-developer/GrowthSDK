Pod::Spec.new do |s|
  s.name             = 'GrowthSDK'
  s.version          = '1.0.0'
  s.summary          = 'GrowthSDK binary distribution.'
  s.description      = 'GrowthSDK xcframework with ad mediation via CocoaPods dependencies.'
  s.homepage         = 'https://example.com/GrowthSDK'
  s.license          = { :type => 'Proprietary', :text => 'All rights reserved.' }
  s.author           = { 'GrowthSDK' => 'support@example.com' }
  # 当使用本地 :path 引入时，CocoaPods 不会读取这个字段的远端内容
  s.source           = { :git => 'https://example.com/GrowthSDK.git', :tag => s.version.to_s }

  s.platform     = :ios, '14.0'
  s.swift_version = '5.9'

  # 交付的二进制
  s.vendored_frameworks = 'Artifacts/GrowthSDK.xcframework'

  # 面向使用方的一些推荐设置
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }

  # 通过 Pod 下发所有广告依赖（由宿主 App 嵌入需要的动态库）
  s.dependency 'AppLovinSDK'
  s.dependency 'AppLovinMediationBigoAdsAdapter'
  s.dependency 'AppLovinMediationChartboostAdapter'
  s.dependency 'AppLovinMediationFyberAdapter'
  s.dependency 'AppLovinMediationGoogleAdapter'
  s.dependency 'AppLovinMediationInMobiAdapter'
  s.dependency 'AppLovinMediationVungleAdapter'
  s.dependency 'AppLovinMediationFacebookAdapter'
  s.dependency 'AppLovinMediationMintegralAdapter'
  s.dependency 'AppLovinMediationByteDanceAdapter'
  s.dependency 'AppLovinMediationMolocoAdapter'
end
