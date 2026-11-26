Pod::Spec.new do |s|
  s.name             = 'SoliqIDKit'
  s.version          = '1.0.0'
  s.summary          = 'SoliqID native iOS: identity check by face (account lookup, session, face capture, compare).'
  s.homepage         = 'https://github.com/usmdroid/soliq_id_kit'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'SICNT' => 'info@yt.uz' }
  s.source           = { :git => 'https://github.com/usmdroid/soliq_id_kit.git', :tag => s.version.to_s }

  s.platform         = :ios, '15.5'
  s.swift_version    = '5.0'
  s.frameworks       = 'UIKit', 'AVFoundation'
  s.vendored_frameworks = 'SoliqIDKit.xcframework'
  s.static_framework = true

  # YuzIDKit is not on CocoaPods trunk: declare it with :git in your Podfile (see README).
  s.dependency 'YuzIDKit', '>= 1.0.3'
end
