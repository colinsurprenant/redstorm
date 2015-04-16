libdir = File.expand_path('../lib/', __FILE__)
$:.unshift libdir unless $:.include?(libdir)

require 'red_storm/version'

Gem::Specification.new do |s|
  s.name        = 'redstorm'
  s.version     = RedStorm::VERSION
  s.authors     = ['Colin Surprenant']
  s.email       = ['colin.surprenant@gmail.com']
  s.homepage    = 'https://github.com/colinsurprenant/redstorm'
  s.summary     = 'JRuby on Storm'
  s.description = 'JRuby integration & DSL for the Storm distributed realtime computation system'
  s.license     = "Apache 2.0"

  s.rubyforge_project = 'redstorm'

  s.files         = Dir.glob("{lib/**/*}") + Dir.glob("{ivy/*.xml}") + Dir.glob("{examples/**/*}") + Dir.glob("{src/**/*.java}") + Dir.glob("{bin/**/*}") + %w(redstorm.gemspec Rakefile README.md CHANGELOG.md LICENSE.md)
  s.require_paths = ['lib']
  s.bindir        = 'bin'
  s.executables   = ['redstorm']

  s.add_development_dependency 'rspec', '~> 2.13'
  s.add_development_dependency 'pry'
  s.add_runtime_dependency 'rake'
end
