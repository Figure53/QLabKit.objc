Pod::Spec.new do |s|
  s.name         = 'QLabKit'
  s.version      = '0.0.5'
  s.summary      = 'An Objective C library for controlling QLab using the OSC API introduced in QLab 3.'
  s.homepage     = 'https://github.com/Figure53/QLabKit.objc'
  s.description  = <<-DESC
  QLabKit is an Objective-C library for controlling QLab over the OSC API in QLab 3 or later. QLabKit requires macOS 11+, iOS 15+, or tvOS 15+.

  NOTE: This library is under active development and the API may change.
                   DESC
  s.license = {
    :type => 'MIT', 
    :file => 'LICENSE.txt'
  }
  s.authors = {
    'Figure 53, LLC' => 'support@figure53.com', 
    'Zach Waugh' => 'zwaugh@gmail.com',
    'Brent Lord' => 'brent@figure53.com'
  }
  s.social_media_url = 'https://twitter.com/figure53'

  s.cocoapods_version = '>= 1.3'
  
  s.ios.deployment_target = '15.0'
  s.tvos.deployment_target = '15.0'
  s.osx.deployment_target = '11.0'
  
  s.source = {
    :git => 'https://github.com/Figure53/QLabKit.objc.git', 
    :tag => "#{s.version}",
  }

  s.pod_target_xcconfig = {
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.figure53.QLabKit'
  }
  
  s.source_files = 'lib/*.{h,m}'
  s.exclude_files = 'lib/F53OSC/*'
  s.dependency 'F53OSC', '~> 1.3'
  s.xcconfig = { 'USER_HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}/F53OSC/*.h"' }
  
  s.frameworks  = 'F53OSC', 'Security'
  s.requires_arc = true

  s.test_spec 'Tests' do |test_spec|
      test_spec.source_files = 'QLabKitDemoTests/*.{h,m}'
  end
end
