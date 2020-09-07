Pod::Spec.new do |s|
  s.name         = "NimiqClient"
  s.version      = "0.0.2"
  s.summary      = "Nimiq JSONRPC Client."
  s.homepage     = "https://github.com/rraallvv/NimiqClientSwift"
  s.license      = "MIT"
  s.author       = { "Nimiq Comunity" => "info@nimiq.com" }
  s.swift_version = "5.0"
  s.module_name  = "NimiqClient"

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"

  s.source       = { :git => "https://github.com/rraallvv/NimiqClientSwift.git", :tag => s.version }
  s.source_files = "Sources/NimiqClient/*.swift"
end
