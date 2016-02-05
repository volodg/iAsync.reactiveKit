platform :ios, '8.0'
use_frameworks!

def import_pods

  pod 'ReactiveKit'      #, '~> 1.1.2'
  pod 'iAsync.async'      , :path => '../iAsync.async'
  pod 'iAsync.utils'      , :path => '../iAsync.utils'
  pod 'iAsync.reactiveKit', :path => '.'
  pod 'ReactiveCocoa'

end

target 'iAsync.reactiveKitApp’, :exclusive => true do
  import_pods
end

target 'iAsync.reactiveKitAppTests', :exclusive => true do
  import_pods
end
