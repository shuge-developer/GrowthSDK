Pod::Spec.new do |s|
  # MARK: - Basic Information
  s.name             = 'GrowthSDK'
  s.version          = '1.0.0'
  s.summary          = 'GrowthSDK binary distribution.'
  s.description      = 'GrowthSDK xcframework with ad mediation via CocoaPods dependencies.'
  s.homepage         = 'https://github.com/shuge-developer/GrowthSDK'
  s.license          = { :type => 'Proprietary', :text => 'All rights reserved.' }
  s.author           = { 'Shuge' => 'shugedeveloper@163.com' }
  s.source           = { :git => 'git@github.com:shuge-developer/GrowthSDK.git', :tag => s.version.to_s }

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
    core.resource_bundles = {
      'GrowthSDKResources' => 'Resources/**/*'
    }
    core.dependency 'AppLovinSDK', '13.3.1'
    core.dependency 'KwaiAdsSDK', '1.2.0'
  end

  s.subspec 'AdsDeps' do |ads|
    # AppLovin Mediation Adapters
    ads.dependency 'AppLovinMediationBigoAdsAdapter', '4.9.3.0'
    ads.dependency 'AppLovinMediationByteDanceAdapter', '7.5.0.5.0'
    ads.dependency 'AppLovinMediationChartboostAdapter', '9.9.2.1'
    ads.dependency 'AppLovinMediationFyberAdapter', '8.3.8.0'
    ads.dependency 'AppLovinMediationGoogleAdapter', '12.9.0.0'
    ads.dependency 'AppLovinMediationInMobiAdapter', '10.8.6.0'
    ads.dependency 'AppLovinMediationVungleAdapter', '7.5.3.0'
    ads.dependency 'AppLovinMediationFacebookAdapter', '6.20.1.0'
    ads.dependency 'AppLovinMediationMintegralAdapter', '7.7.9.0.0'
    ads.dependency 'AppLovinMediationMolocoAdapter', '3.12.1.0'
  end
end
