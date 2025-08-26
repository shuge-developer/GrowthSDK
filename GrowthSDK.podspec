Pod::Spec.new do |s|
  # MARK: - Basic Information
  s.name             = 'GrowthSDK'
  s.version          = '1.0.0'
  s.summary          = 'GrowthSDK binary distribution.'
  s.description      = 'GrowthSDK xcframework with ad mediation via CocoaPods dependencies.'
  s.source           = { :git => 'https://github.com/shuge-developer/GrowthSDK.git', :tag => "v#{s.version}" }
  s.homepage         = 'https://github.com/shuge-developer/GrowthSDK'
  s.license          = { :type => 'Proprietary', :text => 'All rights reserved.' }
  s.author           = { 'Shuge' => 'shugedeveloper@163.com' }

  # MARK: - Platform & Swift Version
  s.platform         = :ios, '14.0'
  s.swift_version    = '5.9'

  # MARK: - Default Configuration
  s.default_subspecs = 'Core'

  # MARK: - Build Settings
  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }

  # MARK: - Core Subspec
  s.subspec 'Core' do |core|
    core.vendored_frameworks = 'Frameworks/GrowthSDK.xcframework'
    core.resources = ['Frameworks/GrowthSDK.xcframework/ios-arm64/GrowthSDK.framework/PrivacyInfo.xcprivacy']
    core.dependency 'AppLovinSDK', '13.3.1'
    core.dependency 'KwaiAdsSDK', '1.2.0'
  end

  # MARK: - Individual Ad Network Adapters (select via subspecs)
  # NOTE: Each adapter depends on Core, so you can do for example:
  #   pod 'GrowthSDK', :subspecs => ['Google', 'Facebook', 'Vungle']

  s.subspec 'AmazonAdMarketplace' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationAmazonAdMarketplaceAdapter', '5.3.0.0'
    sp.dependency 'AmazonPublisherServicesSDK', '5.3.0'
  end
  
  s.subspec 'BidMachine' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationBidMachineAdapter', '3.4.0.0.0'
  end
  
  s.subspec 'ByteDance' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationByteDanceAdapter', '7.5.0.5.0'
  end

  s.subspec 'BigoAds' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationBigoAdsAdapter', '4.9.3.0'
  end
  
  s.subspec 'Chartboost' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationChartboostAdapter', '9.9.2.1'
  end
  
  s.subspec 'CSJ' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationCSJAdapter', '6.7.1.6.0'
  end
  
  s.subspec 'Fyber' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationFyberAdapter', '8.3.8.0'
  end
  
  s.subspec 'GoogleAdManager' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationGoogleAdManagerAdapter', '12.9.0.0'
  end
  
  s.subspec 'Google' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationGoogleAdapter', '12.9.0.0'
  end
  
  s.subspec 'HyprMX' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationHyprMXAdapter', '6.4.2.0.0'
  end
  
  s.subspec 'InMobi' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationInMobiAdapter', '10.8.6.0'
  end
  
  s.subspec 'IronSource' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationIronSourceAdapter', '8.11.0.0.0'
  end
  
  s.subspec 'Vungle' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationVungleAdapter', '7.5.3.0'
  end
  
  s.subspec 'Line' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationLineAdapter', '2.9.20250805.0'
  end
  
  s.subspec 'Maio' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationMaioAdapter', '2.1.6.0'
  end
  
  s.subspec 'Facebook' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationFacebookAdapter', '6.20.1.0'
  end
  
  s.subspec 'Mintegral' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationMintegralAdapter', '7.7.9.0.0'
  end
  
  s.subspec 'MobileFuse' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationMobileFuseAdapter', '1.9.2.1'
  end
  
  s.subspec 'Moloco' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationMolocoAdapter', '3.12.1.0'
  end
  
  s.subspec 'OguryPresage' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationOguryPresageAdapter', '5.1.0.1'
  end
  
  s.subspec 'PubMatic' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationPubMaticAdapter', '4.8.1.0'
  end
  
  s.subspec 'Smaato' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationSmaatoAdapter', '22.9.3.1'
  end
  
  s.subspec 'TencentGDT' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationTencentGDTAdapter', '4.15.21.1'
  end
  
  s.subspec 'UnityAds' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationUnityAdsAdapter', '4.16.1.0'
  end
  
  s.subspec 'Verve' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationVerveAdapter', '3.6.1.0'
  end
  
  s.subspec 'MyTarget' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationMyTargetAdapter', '5.34.1.0'
  end
  
  s.subspec 'Yandex' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationYandexAdapter', '7.15.1.0'
  end
  
  s.subspec 'YSONetwork' do |sp|
    sp.dependency 'GrowthSDK/Core'
    sp.dependency 'AppLovinMediationYSONetworkAdapter', '1.1.31.1'
  end
  
  # MARK: - Recommended Ad Network Bundle
  # Recommended ad network bundle - one-click integration of most commonly used ad network adapters
  # Includes: BigoAds, Chartboost, Fyber, Google, InMobi, Vungle, Facebook, Mintegral, ByteDance, Moloco
  # Usage: pod 'GrowthSDK/Recommended'
  s.subspec 'Recommended' do |re|
    re.dependency 'GrowthSDK/BigoAds'          # BigoAds - Global short video advertising platform
    re.dependency 'GrowthSDK/Chartboost'       # Chartboost - Game advertising optimization platform
    re.dependency 'GrowthSDK/Fyber'            # Fyber - Mobile advertising monetization platform
    re.dependency 'GrowthSDK/Google'           # Google AdMob - World's largest mobile advertising network
    re.dependency 'GrowthSDK/InMobi'           # InMobi - India's leading mobile advertising platform
    re.dependency 'GrowthSDK/Vungle'           # Vungle - Video advertising leader
    re.dependency 'GrowthSDK/Facebook'         # Facebook Audience Network - Meta advertising network
    re.dependency 'GrowthSDK/Mintegral'        # Mintegral - Mobile advertising optimization platform
    re.dependency 'GrowthSDK/ByteDance'        # ByteDance - ByteDance advertising network
    re.dependency 'GrowthSDK/Moloco'           # Moloco - Machine learning advertising platform
  end
end
