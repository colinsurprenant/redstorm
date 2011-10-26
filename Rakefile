require 'ant' 

JRUBY_JAR = '/Users/colin/.rvm/rubies/jruby-1.6.4/lib/jruby.jar'

STORM_DIR = './storm'
JAVA_SRC_DIR = "#{STORM_DIR}/src/jvm"
EXAMPLES_SRC_DIR = "./examples" 
JRUBY_SRC_DIR = "./lib/red_storm" 
RUNTIME_LIB_DIR = "#{STORM_DIR}/lib" 
DEV_LIB_DIR = "#{STORM_DIR}/lib/dev" 
CLASSES_DIR = "#{STORM_DIR}/classes"  
  
task :default => [:clean, :build]  
  
task :clean_all => :clean do  
  ant.delete :dir => RUNTIME_LIB_DIR
end

task :clean do
  ant.delete :dir => CLASSES_DIR
end
  
task :setup do  
  ant.mkdir :dir => CLASSES_DIR  
  ant.path :id => 'classpath' do  
    fileset :dir => RUNTIME_LIB_DIR  
    fileset :dir => DEV_LIB_DIR  
    fileset :dir => CLASSES_DIR  
  end  
end  
  
task :deps do
  system("cd #{STORM_DIR}; ./lein deps")
end

task :build => :setup do
  build_jruby("#{JRUBY_SRC_DIR}")
  build_java("#{JAVA_SRC_DIR}/backtype/storm/jruby")
  build_jruby("#{EXAMPLES_SRC_DIR}")
end  

task :storm do
  unless ENV['class']
    puts("usage: rake storm class={fully qualified java class name}")
    exit(1)
  end
  system("java -cp \"./#{CLASSES_DIR}:./#{RUNTIME_LIB_DIR}/*:./#{DEV_LIB_DIR}/*:#{JRUBY_JAR}\" #{ENV['class']}")
end

def build_java(source_folder)
  puts("\n--> Building Java:")
  ant.javac(
    :srcdir => source_folder,
    :destdir => CLASSES_DIR,
    :classpathref => 'classpath', 
    :source => "1.6",
    :target => "1.6",
    :debug => "yes",
    :includeantruntime => "no",
    :verbose => false,
    :listfiles => true
  )
end  
  
def build_jruby(source_folder)
  puts("\n--> Building JRuby #{source_folder}")
  system("jrubyc -t #{CLASSES_DIR} --verbose --javac -c \"#{DEV_LIB_DIR}/storm-0.5.3.jar\" -c \"#{CLASSES_DIR}\" #{source_folder}")
end
