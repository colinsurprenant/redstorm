require 'ant'

begin
  # will work from gem, since lib dir is in gem require_paths
  require 'red_storm'
rescue LoadError
  # will work within RedStorm dev project
  $:.unshift './lib'
  require 'red_storm'
end
 
INSTALL_STORM_VERSION = "0.7.1"
INSTALL_JRUBY_VERSION = "1.6.7"
DEFAULT_GEMFILE = "Gemfile"

CWD = Dir.pwd
TARGET_DIR = "#{CWD}/target"
TARGET_SRC_DIR = "#{TARGET_DIR}/src"
TARGET_CLASSES_DIR = "#{TARGET_DIR}/classes"  
TARGET_DEPENDENCY_DIR = "#{TARGET_DIR}/dependency"
TARGET_DEPENDENCY_UNPACKED_DIR = "#{TARGET_DIR}/dependency-unpacked"
TARGET_MARKERS_DIR = "#{TARGET_DIR}/dependency-markers"
TARGET_GEMS_DIR = "#{TARGET_DIR}/gems"
TARGET_CLUSTER_JAR = "#{TARGET_DIR}/cluster-topology.jar"

JAVA_SRC_DIR = "#{RedStorm::REDSTORM_HOME}/src/main"
JRUBY_SRC_DIR = "#{RedStorm::REDSTORM_HOME}/lib"

SRC_EXAMPLES = "#{RedStorm::REDSTORM_HOME}/examples"
DST_EXAMPLES = "#{CWD}/examples"

task :launch, :env, :class_file do |t, args|
  version_token = RedStorm::RUNTIME['RUBY_VERSION'] == "--1.9" ? "RUBY1_9" : "RUBY1_8"
  # gem_home = ENV["GEM_HOME"].to_s.empty? ? " -Djruby.gem.home=`gem env home`" : ""
  gem_home = " -Djruby.gem.home=#{RedStorm::GEM_PATH}" 
  command = "java -Djruby.compat.version=#{version_token} -cp \"#{TARGET_CLASSES_DIR}:#{TARGET_DEPENDENCY_DIR}/*\"#{gem_home} redstorm.TopologyLauncher #{args[:env]} #{args[:class_file]}"
  puts("launching #{command}")
  system(command)
end

task :clean do
  ant.delete :dir => TARGET_DIR
end

task :clean_jar do
  ant.delete :file => TARGET_CLUSTER_JAR
end

task :setup do
  puts("\n--> Setting up target directories")
  ant.mkdir :dir => TARGET_DIR 
  ant.mkdir :dir => TARGET_CLASSES_DIR 
  ant.mkdir :dir => TARGET_SRC_DIR
  ant.mkdir :dir => TARGET_GEMS_DIR
  ant.mkdir :dir => "#{TARGET_GEMS_DIR}/gems"
  ant.mkdir :dir => "#{TARGET_GEMS_DIR}/bundler"
  ant.path :id => 'classpath' do  
    fileset :dir => TARGET_DEPENDENCY_DIR  
    fileset :dir => TARGET_CLASSES_DIR  
  end  
end

task :install => [:deps, :build, :gems] do
  puts("\nRedStorm install completed. All dependencies installed in #{TARGET_DIR}")
end

task :unpack do
  system("rmvn dependency:unpack \
          -f #{RedStorm::REDSTORM_HOME}/pom.xml \
          -DoutputDirectory=#{TARGET_DEPENDENCY_UNPACKED_DIR} \
          -DmarkersDirectory=#{TARGET_MARKERS_DIR} \
          -Dstorm-storm.version=#{INSTALL_STORM_VERSION} \
          -Dorg.jruby-jruby-complete.version=#{INSTALL_JRUBY_VERSION}")
end

task :jar, [:include_dir] => [:unpack, :clean_jar] do |t, args|
  ant.jar :destfile => TARGET_CLUSTER_JAR do
    fileset :dir => TARGET_CLASSES_DIR
    fileset :dir => TARGET_DEPENDENCY_UNPACKED_DIR
    fileset :dir => TARGET_GEMS_DIR do
      # remove bundler config dir to avoid setting BUNDLE_PATH
      exclude :name => "bundler/.bundle/**"
    end
    fileset :dir => JRUBY_SRC_DIR do
      exclude :name => "tasks/**"
    end
    fileset :dir => CWD do
      args[:include_dir].split(":").each{|dir| include :name => "#{dir}/**/*"}
    end
    manifest do
      attribute :name => "Main-Class", :value => "redstorm.TopologyLauncher"
    end
  end
  puts("\nRedStorm generated jar file #{TARGET_CLUSTER_JAR}")
end

task :examples do
  if File.identical?(SRC_EXAMPLES, DST_EXAMPLES)
    STDERR.puts("error: cannot copy examples into itself")
    exit(1)
  end
  if File.exist?(DST_EXAMPLES)
    STDERR.puts("error: directory #{DST_EXAMPLES} already exists")
    exit(1)
  end

  puts("copying examples into #{DST_EXAMPLES}")
  system("mkdir #{DST_EXAMPLES}")
  system("cp -r #{SRC_EXAMPLES}/* #{DST_EXAMPLES}")
  puts("\nRedStorm examples completed. All examples copied in #{DST_EXAMPLES}")
end

task :deps => :setup do
  puts("\n--> Installing dependencies")
  system("rmvn dependency:copy-dependencies \
          -f #{RedStorm::REDSTORM_HOME}/pom.xml \
          -DoutputDirectory=#{TARGET_DEPENDENCY_DIR} \
          -DmarkersDirectory=#{TARGET_MARKERS_DIR} \
          -Dstorm-storm.version=#{INSTALL_STORM_VERSION} \
          -Dorg.jruby-jruby-complete.version=#{INSTALL_JRUBY_VERSION}")
end

task :build => :setup do
  # compile the JRuby proxy classes to Java
  build_jruby("#{JRUBY_SRC_DIR}/red_storm/proxy")

  # compile the generated Java proxy classes
  build_java_dir("#{TARGET_SRC_DIR}")

  # generate the JRuby topology launcher
  build_jruby("#{JRUBY_SRC_DIR}/red_storm/topology_launcher.rb")

  # compile the JRuby proxy classes
  build_java_dir("#{JAVA_SRC_DIR}")

  # compile the JRuby proxy classes
  build_java_dir("#{TARGET_SRC_DIR}")
end

task :bundle, [:bundler_options] => :gems do |t, args|
  bundler_options = args[:bundler_options].to_s.split(":").join(" ")

  # basically copy specified Gemfile to target/gems/bundler and install into this dir
  gemfile = bundler_options =~ /--gemfile\s+([^\s]+)/ ? $1 : DEFAULT_GEMFILE
  if bundler_options =~ /--gemfile\s+[^\s]+/
    bundler_options.gsub!(/--gemfile\s+[^\s]+/, "--gemfile #{TARGET_GEMS_DIR}/bundler/Gemfile")
  else
    bundler_options = bundler_options + " --gemfile #{TARGET_GEMS_DIR}/bundler/Gemfile"
  end

  if File.exist?(gemfile)
    puts("\n--> Bundling gems in #{TARGET_GEMS_DIR}/bundler using #{gemfile}")
    system("cp #{gemfile} #{TARGET_GEMS_DIR}/bundler/Gemfile")
    system("export BUNDLE_GEMFILE=; \
            export GEM_PATH=#{RedStorm::GEM_PATH}; \
            jruby #{RedStorm::RUNTIME['RUBY_VERSION']} -S bundle install #{bundler_options} --path #{TARGET_GEMS_DIR}/bundler/")
  elsif gemfile != DEFAULT_GEMFILE
    puts("WARNING: #{gemfile} not found, cannot bundle gems")
  end
end

task :gems => :setup do
  puts("\n--> Installing base gems in #{TARGET_GEMS_DIR}/gems")
  system("gem install bundler --install-dir #{TARGET_GEMS_DIR}/gems --no-ri --no-rdoc --quiet --no-verbose")
  system("gem install rake --install-dir #{TARGET_GEMS_DIR}/gems --no-ri --no-rdoc --quiet --no-verbose")
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
  ) do
    # compilerarg :value => "-Xlint:unchecked"
  end 
end  

def build_jruby(source_path)
  puts("\n--> Compiling JRuby")
  system("cd #{RedStorm::REDSTORM_HOME}; jrubyc -t #{TARGET_SRC_DIR} --verbose --java -c \"#{TARGET_DEPENDENCY_DIR}/storm-#{INSTALL_STORM_VERSION}.jar\" -c \"#{TARGET_CLASSES_DIR}\" #{source_path}")
end
