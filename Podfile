platform :ios, '8.0'
use_frameworks!

def import_pods

pod 'iAsync.async'      , :path => '../iAsync.async'
pod 'iAsync.utils'      , :path => '../iAsync.utils'
pod 'iAsync.reactiveKit', :path => '.'

end

target 'iAsync.reactiveKit', :exclusive => true do
  import_pods
end

target 'iAsync.reactiveKitTests', :exclusive => true do
  import_pods
end
