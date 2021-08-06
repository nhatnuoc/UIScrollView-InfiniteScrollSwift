#
# Be sure to run `pod lib lint UIScrollView-InfiniteScrollSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'UIScrollView-InfiniteScrollSwift'
  s.version          = '0.1.0'
  s.summary          = 'Extension for UIScrollView infinite scroll written by Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Extension for UIScrollView infinite scroll written by Swift. Can be used with UITableView, UICollectionView. 
                       DESC

  s.homepage         = 'https://github.com/nhatnuoc/UIScrollView-InfiniteScrollSwift.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Binh Nguyen (nhatnuoc)' => 'binhvuong.2010@gmail.com' }
  s.source           = { :git => 'https://github.com/nhatnuoc/UIScrollView-InfiniteScrollSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/UIScrollView-InfiniteScrollSwift/**/*'
  s.swift_versions = '5.0'
  
  # s.resource_bundles = {
  #   'UIScrollView-InfiniteScrollSwift' => ['UIScrollView-InfiniteScrollSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
