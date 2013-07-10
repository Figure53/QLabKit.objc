Pod::Spec.new do |s|
  s.name         = "QLabKit"
  s.version      = "0.0.1"
  s.summary      = "Objective-C library controlling QLab 3 over OSC"
  s.homepage     = "http://github.com/Figure53/QLabKit.objc"
  s.license      = 'MIT'
  s.author       = { "Zach Waugh" => "zwaugh@gmail.com" }
  s.source       = { :git => "https://github.com/Figure53/QLabKit.objc.git", :tag => "0.0.1" }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'

  s.source_files = 'lib', 'lib/**/*.{h,m}'
  s.framework  = 'Security'
  s.requires_arc = true
end
