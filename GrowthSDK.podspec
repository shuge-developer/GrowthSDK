Pod::Spec.new do |s|
  s.name             = 'GrowthSDK'
  s.version          = '1.1.2'
  s.summary          = 'GrowthSDK binary distribution.'
  s.description      = 'GrowthSDK xcframework with ad mediation via CocoaPods dependencies.'
  s.homepage         = 'https://codeup.aliyun.com/630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK'
  s.license          = { :type => 'Proprietary', :text => 'All rights reserved.' }
  s.author           = { 'Arvin' => 'arvinSir.86@gmail.com' }
  # 当使用本地 :path 引入时，CocoaPods 不会读取这个字段的远端内容
  s.source           = { :git => 'git@codeup.aliyun.com:630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK.git', :tag => s.version.to_s }

  s.platform     = :ios, '14.0'
  s.swift_version = '5.9'

  # 只默认安装 Core，避免安装 AdsDeps
  s.default_subspecs = 'Core'

  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -ObjC' }

    # Core：仅分发你的二进制 + 核心依赖（如需）
    s.subspec 'Core' do |core|
        core.vendored_frameworks = 'Frameworks/GrowthSDK.xcframework'
        core.dependency 'CryptoSwift', '1.8.4'
        core.dependency 'Alamofire',  '5.10.2'
        # 广告 SDK 依赖移至 AdsDeps 子规范，由下游应用选择性安装
    end

    # AdsDeps：仅分发广告依赖（不含源码、不含你的二进制）
    s.subspec 'AdsDeps' do |ads|
        ads.dependency 'AppLovinSDK', '13.3.1'
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
    end
end
