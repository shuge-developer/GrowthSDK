Pod::Spec.new do |s|
  s.name             = 'GrowthSDK'
  s.version          = '1.0.5'
  s.summary          = 'GrowthSDK binary distribution.'
  s.description      = 'GrowthSDK xcframework with ad mediation via CocoaPods dependencies.'
  s.homepage         = 'https://codeup.aliyun.com/630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK'
  s.license          = { :type => 'Proprietary', :text => 'All rights reserved.' }
  s.author           = { 'Arvin' => 'arvinSir.86@gmail.com' }
  # 当使用本地 :path 引入时，CocoaPods 不会读取这个字段的远端内容
  s.source           = { :git => 'git@codeup.aliyun.com:630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK.git', :tag => s.version.to_s }

  s.platform     = :ios, '14.0'
  s.swift_version = '5.9'

  # 交付的二进制
  s.vendored_frameworks = 'Frameworks/GrowthSDK.xcframework'

  # 面向使用方的一些推荐设置
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }

  # 核心依赖（只影响编译期，不包含广告依赖）
  s.dependency 'CryptoSwift', '1.8.4'
  s.dependency 'Alamofire', '5.10.2'

  # 可选子规格：只下发广告依赖，由宿主 App 链接与嵌入。
  s.subspec 'AdsDeps' do |ads|
    ads.dependency 'AppLovinSDK', '13.3.1'
    # AppLovin 及适配器
    ads.dependency 'AppLovinMediationBigoAdsAdapter'
    ads.dependency 'AppLovinMediationChartboostAdapter'
    ads.dependency 'AppLovinMediationFyberAdapter'
    ads.dependency 'AppLovinMediationGoogleAdapter'
    ads.dependency 'AppLovinMediationInMobiAdapter'
    ads.dependency 'AppLovinMediationVungleAdapter'
    ads.dependency 'AppLovinMediationFacebookAdapter'
    ads.dependency 'AppLovinMediationMintegralAdapter'
    ads.dependency 'AppLovinMediationByteDanceAdapter'
    ads.dependency 'AppLovinMediationMolocoAdapter'

    # 明确声明 Google 广告依赖，锁定版本与当前构建一致，避免 dyld 缺库或版本不匹配
    ads.dependency 'Google-Mobile-Ads-SDK', '12.9.0'
    ads.dependency 'GoogleUserMessagingPlatform', '3.0.0'
  end
end
