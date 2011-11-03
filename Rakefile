require 'ant'

# EDIT JRUBY_JAR to fit your installation
JRUBY_JAR = "$HOME/.rvm/rubies/jruby-1.6.5/lib/jruby-complete-1.6.5.jar"

TARGET_DIR = './target'
TARGET_SRC_DIR = "#{TARGET_DIR}/src"
TARGET_CLASSES_DIR = "#{TARGET_DIR}/classes"  
TARGET_DEPENDENCY_DIR = "#{TARGET_DIR}/dependency"

JAVA_SRC_DIR = "./src/main"
JRUBY_SRC_DIR = "./lib/red_storm" 
  
task :default => [:clean, :build]  
  
task :clean_deps => :clean do  
  ant.delete :dir => TARGET_DEPENDENCY_DIR
end

task :clean do
  ant.delete :dir => TARGET_CLASSES_DIR
  ant.delete :dir => TARGET_SRC_DIR
end
  
task :setup do  
  ant.mkdir :dir => TARGET_DIR 
  ant.mkdir :dir => TARGET_CLASSES_DIR 
  ant.mkdir :dir => TARGET_SRC_DIR
  ant.path :id => 'classpath' do  
    fileset :dir => TARGET_DEPENDENCY_DIR  
    fileset :dir => TARGET_CLASSES_DIR  
  end  
end  
  
task :deps do
  system("rmvn dependency:copy-dependencies")
  system("cp #{JRUBY_JAR} #{TARGET_DEPENDENCY_DIR}")
end

task :build => :setup do
  # generate the JRuby proxy classes in java, required by the Java bindings
  build_jruby("#{JRUBY_SRC_DIR}/proxy")

  # compile the JRuby proxy classes
  build_java_dir("#{TARGET_SRC_DIR}")

  # generate the JRuby proxy classes in java, required by the Java bindings
  build_jruby("#{JRUBY_SRC_DIR}/topology_launcher.rb")

  # compile the JRuby proxy classes
  build_java_dir("#{JAVA_SRC_DIR}")

  # compile the JRuby proxy classes
  build_java_dir("#{TARGET_SRC_DIR}")
end  

def build_java_dir(source_folder)
  puts("\n--> Compiling Java")
  ant.javac(
    :srcdir => source_folder,
    :destdir => TARGET_CLASSES_DIR,
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
  puts("\n--> Compiling JRuby")
  system("jrubyc -t #{TARGET_SRC_DIR} --verbose --java -c \"#{TARGET_DEPENDENCY_DIR}/storm-0.5.3.jar\" -c \"#{TARGET_CLASSES_DIR}\" #{source_folder}")
end
