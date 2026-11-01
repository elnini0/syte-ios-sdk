#
# Be sure to run `pod lib lint Syte.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Syte'
  s.version          = '3.0.0'
  s.summary          = 'Syte SDK: visual search, recommendations, text search and event tracking'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = "Site SDK"

  s.homepage         = 'https://github.com/elnini0/syte-ios-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tarasenko.artur' => 'artur.tarasenko@cloverdynamics.com' }
  s.source           = { :git => 'https://github.com/elnini0/syte-ios-sdk.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  #  s.static_framework = true
  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5']

  s.source_files = 'Sources/iOS-SDK/Syte/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Syte' => ['Sources/iOS-SDK/Syte/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'Moya', '~> 15.0'
   s.dependency 'PromiseKit', '~> 6.18'
  
end
