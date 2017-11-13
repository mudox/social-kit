Pod::Spec.new do |s|

  s.name             = 'SocialKit'
  s.version          = '0.1.0'
  s.summary          = 'My all-in-one social share SDK library.'

  s.description      = <<-DESC
  My social share wrapper of the commonly used social sharing frameworks.
  Provide uniform completion block based interface for Objective-C project,
  PromiseKit wrapping for Swift project.
  DESC

  s.homepage         = 'https://github.com/mudox/social-kit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mudox' => 'mudoxisme@gmail.com' }

  s.source           = { :git => 'https://github.com/mudox/social-kit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'SocialShare/Source/**/*.{h,m,swift}', 'SocialShare/Library/**/*.{h,m,swift}'
  s.public_header_files = 'SocialShare/Source/{Types,SSError,SSOResult,SocialShare}.h', 'SocialShare/Library/**/*.h'
  s.resources = 'SocialShare/Library/**/*.bundle', 'SocialShare/Library/**/*.framework'

  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-all_load' }

  s.frameworks = 'Photos', 'ImageIO', 'SystemConfiguration', 'CoreText', 'QuartzCore', 'Security', 'UIKit', 'Foundation', 'CoreGraphics', 'CoreTelephony'
  s.libraries = 'stdc++', 'sqlite3', 'iconv', 'c++', 'sqlite3', 'z'
  s.vendored_libraries = 'SocialShare/Library/**/*.a'
  s.vendored_frameworks = 'SocialShare/Library/**/*.framework'

  s.dependency 'Jack'
  s.dependency 'PromiseKit'

end
