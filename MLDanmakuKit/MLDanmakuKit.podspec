#
# Be sure to run `pod lib lint MLDanmakuKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MLDanmakuKit'
  s.version          = '1.0.0'
  s.summary          = '一款简单易用的高性能弹幕引擎'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'MLDanmakuKit是一款iOS平台上的高性能弹幕引擎，支持自定义弹幕样式，直播和点播两种模式；简单易上手，API类似UITableView,开发者几乎不需要任何学习成本就能轻松上手；性能表现优异，CPU占用率极低，不阻塞主线程。'

  s.homepage         = 'https://git.woa.com/QQSports_iOS/MLDanmaku.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mountainsli' => 'lishan_workemail@163.com' }
  s.source           = { :git => 'https://git.woa.com/QQSports_iOS/MLDanmaku.git', :branch => "master" }

  s.ios.deployment_target = '9.0'

  s.source_files = 'DanmaKu/**/*.{h,m}'
  
   s.public_header_files = 'DanmaKu/**/*.h'
   s.frameworks = 'UIKit'
end
