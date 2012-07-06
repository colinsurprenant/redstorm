# 0.1.0, 11-07-2011
- initial release

# 0.1.1, 11-10-2011
- issue #1 cannot find redstorm gem when using rbenv

# 0.2.0, 11-16-2011
- issue #2 redstorm examples fails when directory examples already exists
- new *simple* DSL
- examples using simple DSL
- redstorm command usage syntax change
- more doc in README

# 0.2.1, 11-23-2011
- gems support in production cluster

# 0.3.0, 12-08-2011
- Storm 0.6.0

# 0.4.0, 02-08-2012
- Storm 0.6.2
- JRuby 1.6.6

# 0.5.0, 05-28-2012
- issue #16, Bundler support for topology gems
- issue #19, support for multiple dirs in jar
- issue #20, update to Storm 0.7.1
- issue #21, proper support for 1.8/1.9 Ruby compatibility mode
- issue #22, fixed Config class name clash
- JRuby 1.6.7
- DSL Support for per bolt/spout configuration and spout activate/deactivate in Storm 0.7.x
- consistent workflow using the redstorm command in local dev or gem mode

# 0.5.1, 06-05-2012
- better handling of enviroments and paths
- redstorm bundle command to install topology gems
- issue #26, fixed examples/native for 0.5.1 compatibility

# 0.6.0, 06-27-2012
- issue #29, updated to Storm 0.7.3
- issue #30, add redstorm cluster command for remote topology submission
- issue #31, added support for localOrShuffleGrouping
- issue #33, avoid forking or shelling out on redstorm commands
- JRuby 1.6.7.2
- better handling of JRuby 1.8/1.9 mode
- topology gems are now specified using a Bundler group in the project Gemfile
- refactored environment/paths handling for local vs cluster context

# 0.6.1, tbd
- issue #38, added support for spout reliable emit