$:.unshift File.dirname(__FILE__) + '/../lib/'
$:.unshift File.dirname(__FILE__) + '/../spec'

require 'rspec'

# load Storm jars
storm_jars = File.dirname(__FILE__) + '/../target/dependency/storm/default/*.jar'
Dir.glob(storm_jars).each{|f| require f}
