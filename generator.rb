require 'erb'
require 'pry'

require 'java'
require 'active_support/core_ext'

Dir["../triggit-storm/target/dependency/storm/default/*"].each{|f| $CLASSPATH << File.expand_path(f) }


PROXY_JRUBY_TEMPLATE = File.read("./ruby_proxy.erb")
PROXY_JAVA_TEMPLATE = File.read("./java_proxy.erb")

to_generate = ["storm.trident.operation.Function"]


# Return all java functions of a java class
def get_functions(jlass)
  jlass.declared_instance_methods.concat( jlass.interfaces.map{|i| get_functions(i) }.flatten )
end

# Return all java deps of a class
def get_java_deps(functions, klass)
  functions.map{|f| [f.argument_types.map{|at| at.name}, f.return_type ? f.return_type.name : "void"] }.flatten.uniq.reject{|t| t.split('.').count == 1} << klass
end

to_generate.each do |klass|
  _functions = get_functions(Object.const_get(java_import(klass)[0].to_s.split("::")[-1]).java_class)

  java_deps = get_java_deps(_functions, klass)


  # Boil down functions to {:function_name => {:return_type => type, :args => {:arg_var_name => :arg_var_type, ...} } }
  functions = _functions.reduce({}) do |memo, f|
    memo[:"#{f.name}"] = {
      :return_type => f.return_type ? f.return_type.name.split('.')[-1] : "void",
      :args => f.argument_types.map {|at| {:"_#{at.name.split('.')[-1].camelize(:lower)}" => at.name.split('.')[-1]} }.reduce({}){|m,o| m.merge(o)}
    }
    memo
  end

  interface_name = klass.split(".")[-1]

  # IBlah to Blah if IBlah
  ruby_class_name = interface_name.starts_with?('I') ? interface_name[1..-1] : interface_name

  java_class_name = "JRuby#{ruby_class_name}"

  # Rubyify java functions into {:method_name => {:return_type => type, :args => {:arg_var_name => :arg_var_type, ...} } }
  methods = functions.map do |f_name, params|
    {f_name.to_s.underscore.to_sym => {:return_type => params[:return_type], :args => params[:args].map{|name, type| {name.to_s.underscore.to_sym => type}}.reduce({}){|m,o| m.merge(o)} }}
  end.reduce({}){|m,o| m.merge(o)}

  File.open("./lib/red_storm/proxy/#{ruby_class_name.underscore}.rb", 'w') {|f| f.write(ERB.new(PROXY_JRUBY_TEMPLATE).result(binding)) }
  File.open("./src/main/redstorm/storm/jruby/#{java_class_name}.java", 'w') {|f| f.write(ERB.new(PROXY_JAVA_TEMPLATE).result(binding)) }
end
