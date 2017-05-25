Pod::Spec.new do |s|  
	s.name             = "HMLogger"  
	s.version          = "2.0.0"  
	s.summary          = "simple, pretty and powerful logger for iOS with piker、viewer、console"  
	s.homepage         = "https://github.com/393385724/DDLogger"  
	s.license          = 'MIT'  
	s.author           = { "llg" => "393385724@qq.com" }  
	s.source           = { :git => "https://github.com/393385724/DDLogger.git", :tag => s.version.to_s }  

	s.platform     = :ios, '8.0'  
	s.ios.deployment_target = '8.0'  
	s.requires_arc = true  


	s.source_files  = 'HMLogger/*.{h,m,mm}','HMLogger/Mars/*.{h,cc}'
	s.public_header_files = 'HMLogger/HMLogger.h','HMLogger/HMLoggerDefine.h'
	s.ios.vendored_frameworks = 'HMLogger/Mars/*.framework'
	s.ios.resources = ['HMLogger/*.png','HMLogger/*.xib']
	s.frameworks = 'CoreTelephony','SystemConfiguration','Foundation', 'CoreGraphics', 'UIKit'
	s.libraries = 'z','stdc++'
	s.user_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
	s.dependency 'ICTextView', '~> 2.0.1'
	s.dependency 'CocoaLumberjack', '~> 3.2.0'

end  
