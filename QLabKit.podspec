Pod::Spec.new do |s|
  s.name         = 'QLabKit'
  s.version      = '0.0.3'
  s.summary      = 'An Objective C library for controlling QLab using the OSC API introduced in QLab 3.'
  s.homepage     = 'https://github.com/Figure53/QLabKit.objc'
  s.description  = <<-DESC
  QLabKit is an Objective-C library for controlling QLab over the OSC API in QLab 3 or later. QLabKit requires macOS 10.9+ or iOS 8.4+.

  NOTE: This library is under active development and the API may change.
                   DESC
  s.license      = { 
    :type => 'MIT', 
    :file => 'LICENSE.txt'
  }
  s.authors      = { 
    'Figure 53, LLC' => 'support@figure53.com', 
    'Zach Waugh' => 'zwaugh@gmail.com',
    'Brent Lord' => 'brent@figure53.com'
  }
  s.social_media_url   = 'http://twitter.com/figure53'
  
  s.ios.deployment_target = '8.4'
  # s.osx.deployment_target = '10.9' ### OS X disabled for now because F53OSC podspec 1.0.1 does not support OS X yet
  
  s.source       = {
    :git => 'https://github.com/Figure53/QLabKit.objc.git', 
    :tag => "#{s.version}",
  }
  
  s.source_files = 'lib/*.{h,m}'
  s.exclude_files = 'lib/F53OSC/*'
  s.dependency 'F53OSC', '1.0.2'
  s.dependency 'CocoaLumberjack', '~> 2.2.0'
  
  s.frameworks  = 'Security', 'GLKit'
  s.requires_arc = true
end
