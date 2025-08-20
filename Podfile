# Uncomment the next line to define a global platform for your project
install! 'cocoapods', :warn_for_unused_master_specs_repo => false
platform :ios, '14.0'

target 'GrowthSDK' do
  use_frameworks! :linkage => :static
  
  pod 'AppLovinSDK', '13.3.1'
  pod 'KwaiAdsSDK', '1.2.0'
  
  pod 'ThinkingSDK', '3.1.4'
  pod 'Google-Mobile-Ads-SDK', '12.9.0'
  pod 'BigoADS', '4.9.3'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['DEFINES_MODULE'] = 'YES'
      config.build_settings['SKIP_INSTALL'] = 'NO'
    end
  end
end
