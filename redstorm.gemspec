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
 
  s.rubyforge_project = 'redstorm'
  
  s.files         = Dir.glob("{lib/**/*}") + Dir.glob("{ivy/settings.xml}") + Dir.glob("{examples/**/*}") + Dir.glob("{src/**/*.java}") + Dir.glob("{bin/**/*}") + %w(Rakefile README.md CHANGELOG.md LICENSE.md)
  s.require_paths = ['lib']
  s.bindir        = 'bin'
  s.executables   = ['redstorm']

  s.add_development_dependency 'rspec', '~> 2.11.0'
  s.add_runtime_dependency 'rake'
end
