#
# Be sure to run `pod lib lint LXMDownloader.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LXMDownloader'
  s.version          = '0.0.3'
  s.summary          = '一个封装好的文件下载库，可以用来下载视频或其他文件，支持后台下载，断点续传'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Phelthas/LXMDownloader'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'billthas@gmail.com' => 'billthas@gmail.com' }
  s.source           = { :git => 'https://github.com/Phelthas/LXMDownloader.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.swift_version = '4.2'

  s.source_files = 'LXMDownloader/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LXMDownloader' => ['LXMDownloader/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'AFNetworking', '~> 3.2.1'
end
