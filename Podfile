platform :ios, '8.0'
use_frameworks!

def import_pods

  pod 'ReactiveKit'      #, '~> 1.1.2'
  pod 'iAsync.utils'      , :path => '../iAsync.utils'
  pod 'iAsync.reactiveKit', :path => '.'

end

target 'iAsync.reactiveKitApp' do
  import_pods
end

target 'iAsync.reactiveKitAppTests' do
  import_pods
end
