# Uncomment the next line to define a global platform for your project
install! 'cocoapods', :warn_for_unused_master_specs_repo => false
platform :ios, '14.0'

target 'GrowthSDK' do
  use_frameworks! :linkage => :static
  
  pod 'AppLovinSDK'
  pod 'CryptoSwift'
  
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
