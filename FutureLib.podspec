Pod::Spec.new do |spec|
  spec.name = 'FutureLib'
  spec.version = '1.0.1'
  spec.summary = 'FutureLib is a pure Swift 2 library implementing Skala-like Futures & Promises'
  spec.license = 'Apache License, Version 2.0'
  spec.homepage = 'https://github.com/couchdeveloper/FutureLib'
  spec.authors = { 'Andreas Grosam' => 'couchdeveloper@gmail.com' }
  spec.source = { :git => 'https://github.com/couchdeveloper/FutureLib.git', :tag => "#{spec.version}" }

  spec.osx.deployment_target = '10.10'
  spec.ios.deployment_target = '8.0'
  spec.tvos.deployment_target = '9.0'
  spec.watchos.deployment_target = '2.0'

  spec.source_files = "Sources/*.swift", "Sources/**/*.swift"

  spec.requires_arc = true
end
