Pod::Spec.new do |s|
  # MARK: - Basic Information
  s.name             = 'GrowthSDK'
  s.version          = '1.1.6'
  s.summary          = 'GrowthSDK binary distribution.'
  s.description      = 'GrowthSDK xcframework with ad mediation via CocoaPods dependencies.'
  s.homepage         = 'https://codeup.aliyun.com/630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK'
  s.license          = { :type => 'Proprietary', :text => 'All rights reserved.' }
  s.author           = { 'Arvin' => 'arvinSir.86@gmail.com' }
  s.source           = { :git => 'git@codeup.aliyun.com:630b1207050e9c4a07a93a48/IOS/SDK/GrowthSDK.git', :tag => s.version.to_s }

  # MARK: - Platform & Swift Version
  s.platform         = :ios, '14.0'
  s.swift_version    = '5.9'

  # MARK: - Default Configuration
  s.default_subspecs = 'Core'

  # MARK: - Build Settings
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }

  # MARK: - Subspecs
  s.subspec 'Core' do |core|
    core.vendored_frameworks = 'Frameworks/GrowthSDK.xcframework'
  end

  s.subspec 'AdsDeps' do |ads|
    # AppLovin Mediation Adapters
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
