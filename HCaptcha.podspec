
Pod::Spec.new do |s|
  s.name             = 'HCaptcha'
  s.version          = '1.6.0'
  s.summary          = 'HCaptcha for iOS'
  s.swift_version    = '5.0'
  
  s.description      = <<-DESC
Add [hCaptcha](https://hcaptcha.com) to your project. This library
automatically handles HCaptcha's events and retrieves the validation token or notifies you to present the challenge if
invisibility is not possible.
                       DESC

  s.homepage          = 'https://github.com/hCaptcha/HCaptcha-ios-sdk'
  s.license           = { :type => 'MIT', :file => 'LICENSE' }
  s.author            = { 'hCaptcha Team' => 'support@hcaptcha.com' }
  s.source            = { :git => 'https://github.com/hCaptcha/HCaptcha-ios-sdk.git', :tag => s.version.to_s }
  s.social_media_url  = 'https://twitter.com/hCaptcha'
  s.documentation_url = 'https://github.com/hCaptcha/HCaptcha-ios-sdk'

  s.ios.deployment_target = '8.0'
  s.default_subspecs = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'HCaptcha/Classes/*'
    core.frameworks = 'WebKit'

    core.resource_bundles = {
      'HCaptcha' => ['HCaptcha/Assets/**/*']
    }
  end

  s.subspec 'RxSwift' do |rx|
    rx.source_files = 'HCaptcha/Classes/Rx/**/*'
    rx.dependency 'HCaptcha/Core'
    rx.dependency 'RxSwift', '~> 6.0'
  end
end
