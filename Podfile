xcodeproj 'meWrap.xcodeproj'
platform :ios, '8.0'
use_frameworks!

def extension_pods
    pod 'MMWormhole', '~> 2.0.0'
end

target 'meWrap' do
    pod 'AFNetworking'
    pod 'PubNub', '~> 4.0'
    pod 'LogEntries'
    pod 'OpenUDID'
    pod 'AWSCore'
    pod 'AWSS3'
    pod 'libPhoneNumber-iOS', '~> 0.8'
    pod 'Google/Analytics', '~> 1.0.0'
    pod 'NewRelicAgent'
    pod 'CryptoSwift'
    extension_pods
end

target 'meWrapToday' do
    extension_pods
end