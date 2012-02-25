lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'red_storm/version'

Gem::Specification.new do |s|  
  s.name        = "redstorm"
  s.version     = RedStorm::VERSION
  s.authors     = ["Colin Surprenant"]
  s.email       = ["colin.surprenant@gmail.com"]
  s.homepage    = "https://github.com/colinsurprenant/redstorm"
  s.summary     = "JRuby on Storm"
  s.description = "JRuby integration & DSL for the Storm distributed realtime computation system"
 
  s.required_rubygems_version = ">= 1.3.0"
  s.rubyforge_project = "redstorm"
  
  s.files         = Dir.glob("{lib/**/*}") + Dir.glob("{examples/**/*.rb}") + Dir.glob("{src/**/*.java}") + Dir.glob("{bin/**/*}") + %w(Rakefile pom.xml README.md CHANGELOG.md LICENSE.md TODO.md)
  s.require_paths = %w[lib]
  s.bindir        = 'bin'
  s.executables   = ['redstorm']

  s.add_development_dependency "rubyforge"

  s.add_runtime_dependency "rake", ["~> 0.9.2.2"]
  s.add_runtime_dependency "ruby-maven", ["~> 3.0.3.0.28.5"]
end

