require 'erb'
require 'pry'

require 'java'
require 'active_support/core_ext'

Dir["../triggit-storm/target/dependency/storm/default/*"].each{|f| $CLASSPATH << File.expand_path(f) }

to_generate = ["storm.trident.spout.IBatchSpout"]


PROXY_JRUBY_TEMPLATE = File.read("./ruby_proxy.erb")
PROXY_JAVA_TEMPLATE = File.read("./java_proxy.erb")

to_generate = ["storm.trident.spout.IBatchSpout"]


to_generate.each do |klass|
  _functions = Object.const_get(java_import(klass)[0].to_s.split("::")[-1]).java_class.declared_instance_methods

  java_deps = _functions.map{|f| [f.argument_types.map{|at| at.name}, f.return_type ? f.return_type.name : "void"] }.flatten.uniq.reject{|t| t.split('.').count == 1} << klass

  functions = _functions.reduce({}) do |memo, f|
    memo[:"#{f.name}"] = {
      :return_type => f.return_type ? f.return_type.name.split('.')[-1] : "void",
      :args => f.argument_types.map {|at| {:"_#{at.name.split('.')[-1].camelize(:lower)}" => at.name.split('.')[-1]} }.reduce({}){|m,o| m.merge(o)}
    }
    memo
  end

  interface_name = klass.split(".")[-1]

  ruby_class_name = interface_name[1..-1]

  java_class_name = "JRuby#{ruby_class_name}"

  methods = functions.map do |f_name, params|
    {f_name.to_s.underscore.to_sym => {:return_type => params[:return_type], :args => params[:args].map{|name, type| {name.to_s.underscore.to_sym => type}}.reduce({}){|m,o| m.merge(o)} }}
  end.reduce({}){|m,o| m.merge(o)}

  File.open("./lib/red_storm/proxy/#{ruby_class_name.underscore}.rb", 'w') {|f| f.write(ERB.new(PROXY_JRUBY_TEMPLATE).result(binding)) }
  File.open("./src/main/redstorm/storm/jruby/#{java_class_name}.java", 'w') {|f| f.write(ERB.new(PROXY_JAVA_TEMPLATE).result(binding)) }
end
