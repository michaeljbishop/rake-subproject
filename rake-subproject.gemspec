# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "#{lib}/rake/subproject/version"

Gem::Specification.new do |spec|
  spec.name          = "rake-subproject"
  spec.version       = Rake::Subproject::VERSION
  spec.authors       = ["Michael Bishop"]
  spec.email         = ["mbtyke@gmail.com"]
  spec.summary       = "Allows bridging of sub-projects into super-projects"
#   spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.start_with?('resources/')
  end + Dir["lib/rake/subproject/{client,server}/*.rb"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.required_ruby_version = '~> 2.0'
  
  spec.add_runtime_dependency "rake"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rspec"
end
