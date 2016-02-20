#
# Be sure to run `pod lib lint PlayerView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PlayerView"
  s.version          = "0.1.3"
  s.summary          = "A UIView for videos using AVPlayer with delegate"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                        This Library allows to set a video on a custom UIView by setting the callbacks on a delegate for easy use. this View implements the AVPlayer from AVFoundation
                       DESC

  s.homepage         = "https://github.com/davidlondono/PlayerView"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "David Alejandro" => "davidlondono9@gmail.com" }
  s.source           = { :git => "https://github.com/davidlondono/PlayerView.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/davidlondono'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Sources/**/*'
  s.resource_bundles = {
    'PlayerView' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
