Pod::Spec.new do |s|  
  s.name             = "DDLogger"  
  s.version          = "1.3.0"  
  s.summary          = "simple, pretty and powerful logger for iOS with piker、viewer、console"  
  s.homepage         = "https://github.com/393385724/DDLogger"  
  s.license          = 'MIT'  
  s.author           = { "llg" => "393385724@qq.com" }  
  s.source           = { :git => "https://github.com/393385724/DDLogger.git", :tag => s.version.to_s }  
  
  s.platform     = :ios, '7.0'  
  s.ios.deployment_target = '7.0'  
  s.requires_arc = true  
  
  s.ios.source_files = 'DDLogger/*.{h,m}','DDLogger/Mars/*.{h,cc}'
  s.public_header_files = 'DDLogger/DDLogger.h'
  s.libraries = 'z'
  s.ios.vendored_frameworks = 'DDLogger/Mars/*.framework'
  s.ios.resources = ['DDLogger/*.png','DDLogger/*.xib']
  s.user_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
  
  s.frameworks = 'Foundation', 'CoreGraphics', 'UIKit','CoreTelephony','SystemConfiguration'
  s.dependency 'ICTextView', '~> 2.0.1'

end  
