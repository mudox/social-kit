Pod::Spec.new do |s|

  s.name             = 'SocialKit'
  s.version          = '0.1.0'
  s.summary          = 'My all-in-one social SDK library.'

  s.description      = <<-DESC
  TBD
  DESC

  s.homepage         = 'https://github.com/mudox/social-kit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = 'mudox'

  s.source           = { :git => 'https://github.com/mudox/social-kit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = [
    'SocialKit/Source/**/*.{h,m,swift}',
    'SocialKit/Library/**/*.{h,m,swift}'
  ]
  s.public_header_files = [
    'SocialKit/Source/{Types,SSError,SSOResult,SocialKit}.h',
    'SocialKit/Library/**/*.h'
  ]
  s.resources = [
    'SocialKit/Library/**/*.bundle',
    'SocialKit/Library/**/*.framework'
  ]

  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '-all_load' }

  s.frameworks = [
    'Photos', 'ImageIO', 'SystemConfiguration', 'CoreText', 'QuartzCore',
    'Security', 'UIKit', 'Foundation', 'CoreGraphics', 'CoreTelephony'
  ]
  s.libraries = 'stdc++', 'sqlite3', 'iconv', 'c++', 'sqlite3', 'z'

  s.vendored_libraries = 'SocialKit/Library/**/*.a'
  s.vendored_frameworks = 'SocialKit/Library/**/*.framework'

  s.dependency 'JacKit'
  s.dependency 'PromiseKit'

end
