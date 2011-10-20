require 'ant'  
  
PROJECT_NAME = 'storm-jruby'  
  
JAVA_SRC_DIR = 'src/jvm'  
JRUBY_SRC_DIR = 'src/jruby'  
 
RUNTIME_LIB_DIR = 'lib'  
DEV_LIB_DIR = 'lib/dev' 
JRUBY_JAR = '/Users/colin/.rvm/rubies/jruby-1.6.4/lib/jruby.jar'
  
BUILD_DIR = 'build'  
CLASSES_DIR = "classes"  
  
task :default => [:clean, :build]  
  
task :clean do  
  ant.delete :dir => BUILD_DIR  
  puts  
end  
  
task :setup do  
  ant.mkdir :dir => CLASSES_DIR  
  ant.path :id => 'classpath' do  
    fileset :dir => RUNTIME_LIB_DIR  
    fileset :dir => DEV_LIB_DIR  
    fileset :dir => CLASSES_DIR  
  end  
end  
  
task :build => :setup do
  build_java "#{JAVA_SRC_DIR}/backtype/storm/jruby"
  build_jruby "#{JRUBY_SRC_DIR}/storm/starter"
end  
  
def build_java(source_folder)  
  ant.javac :srcdir => source_folder, :destdir => CLASSES_DIR, :classpathref => 'classpath',  
            :source => "1.6", :target => "1.6", :debug => "yes", :includeantruntime => "no"  
  puts  
end  
  
def build_jruby(source_folder)
  puts("compiling jruby")
  exec("jrubyc -t #{CLASSES_DIR} --javac -c \"#{DEV_LIB_DIR}/storm-0.5.3.jar\" -c \"#{CLASSES_DIR}\" #{JRUBY_SRC_DIR}")
end  


task :storm do
  unless ENV['class']
    puts("usage: rake storm class={fully qualified java class name}")
    exit(1)
  end
  exec("java -cp \"./#{CLASSES_DIR}:./#{RUNTIME_LIB_DIR}/*:./#{DEV_LIB_DIR}/*:#{JRUBY_JAR}\" #{ENV['class']}")
end

  
