# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rack-streaming-proxy"
  s.version = "2.0.0"
  s.authors = ["Nathan Witmer", "Tom Lea"]
  s.email = ["nwitmer@gmail.com", "contrib@tomlea.co.uk"]
  s.description = "Streaming proxy for Rack, the rainbows to Rack::Proxy's unicorn."
  s.summary = "Streaming HTTP proxy for Rack."
  s.homepage = "http://github.com/zerowidth/rack-streaming-proxy"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "rack", ">= 1.0"
  s.add_development_dependency "puma"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
end
