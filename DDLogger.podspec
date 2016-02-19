Pod::Spec.new do |s|  
  s.name             = "DDLogger"  
  s.version          = "0.0.2"  
  s.summary          = "Simple, pretty and powerful logger for iOS"  
  s.homepage         = "https://github.com/393385724/DDLogger"  
  s.license          = 'MIT'  
  s.author           = { "llg" => "393385724@qq.com" }  
  s.source           = { :git => "https://github.com/393385724/DDLogger.git", :tag => s.version.to_s }  
  
  s.platform     = :ios, '7.0'  
  s.ios.deployment_target = '7.0'  
  s.requires_arc = true  
  s.source_files = 'DDLogger/*.{m,h}'
  s.frameworks = 'Foundation', 'CoreGraphics', 'UIKit'

end  
