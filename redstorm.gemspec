lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'red_storm/version'

Gem::Specification.new do |s|  
  s.name        = "redstorm"
  s.version     = RedStorm::VERSION
  s.authors     = ["Colin Surprenant"]
  s.email       = ["colin.surprenant@gmail.com"]
  s.homepage    = "http://github.com/praized/storm-jruby"
  s.summary     = "Storm JRuby Bindings"
  s.description = "Storm JRuby Bindings Gem"
 
  s.required_rubygems_version = ">= 1.3.0"
  s.rubyforge_project = "redstorm"
  
  s.files         = Dir.glob("{lib/**/*.rb}") + Dir.glob("{examples/**/*.rb}") + Dir.glob("{src/**/*.java}") + Dir.glob("{bin/**/*}") + %w(Rakefile pom.xml README.md CHANGELOG.md LICENSE.md)
  s.require_paths = %w[lib]
  s.bindir        = 'bin'
  s.executables   = ['redstorm']

  s.add_development_dependency "rubyforge"

  # Test dependencies
  s.add_development_dependency "rspec", ["~> 2.6.0"]
  s.add_development_dependency "rake", ["~> 0.9.2"]

  s.add_runtime_dependency "ruby-maven", ["~> 3.0.3.0.28.5"]
end

