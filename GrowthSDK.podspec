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
