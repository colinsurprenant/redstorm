require 'ant'
require 'jruby/jrubyc'
require 'pompompom'
require 'red_storm'

# begin
#   # will work from gem, since lib dir is in gem require_paths
#   require 'red_storm'
# rescue LoadError
#   # will work within RedStorm dev project
#   $:.unshift './lib'
#   require 'red_storm'
# end
 
INSTALL_STORM_VERSION = "0.7.1"
INSTALL_JRUBY_VERSION = "1.6.7"
DEFAULT_GEMFILE = "Gemfile"

CWD = Dir.pwd
TARGET_DIR = "#{CWD}/target"
TARGET_LIB_DIR = "#{TARGET_DIR}/lib"
TARGET_SRC_DIR = "#{TARGET_DIR}/src"
TARGET_CLASSES_DIR = "#{TARGET_DIR}/classes"  
TARGET_DEPENDENCY_DIR = "#{TARGET_DIR}/dependency"
TARGET_DEPENDENCY_UNPACKED_DIR = "#{TARGET_DIR}/dependency-unpacked"
TARGET_MARKERS_DIR = "#{TARGET_DIR}/dependency-markers"
TARGET_CLUSTER_JAR = "#{TARGET_DIR}/cluster-topology.jar"

REDSTORM_JAVA_SRC_DIR = "#{RedStorm::REDSTORM_HOME}/src/main"
REDSTORM_LIB_DIR = "#{RedStorm::REDSTORM_HOME}/lib"

SRC_EXAMPLES = "#{RedStorm::REDSTORM_HOME}/examples"
DST_EXAMPLES = "#{CWD}/examples"

module JavaZip
  import 'java.util.zip.ZipFile'
end

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
  ant.mkdir :dir => TARGET_DEPENDENCY_DIR
  ant.mkdir :dir => TARGET_SRC_DIR
  ant.mkdir :dir => RedStorm::GEM_PATH
  ant.path :id => 'classpath' do  
    fileset :dir => TARGET_DEPENDENCY_DIR  
    fileset :dir => TARGET_CLASSES_DIR  
  end  
end

task :install => [:deps, :build, :copy_red_storm] do
  puts("\nRedStorm install completed. All dependencies installed in #{TARGET_DIR}")
end

task :unpack do
  unpack_artifacts = %w[jruby-complete]
  unpack_glob = "#{TARGET_DEPENDENCY_DIR}/{#{unpack_artifacts.join(',')}}-*-jar.jar"
  Dir[unpack_glob].each do |jar|
    puts("Extracting #{jar}")
    zf = JavaZip::ZipFile.new(jar)
    zf.entries.each do |entry|
      next if entry.directory?
      destination = "#{TARGET_DEPENDENCY_UNPACKED_DIR}/#{entry.name}"
      in_io = zf.get_input_stream(entry).to_io
      FileUtils.mkdir_p(File.dirname(destination))
      File.open(destination, 'w') { |out_io| out_io.write(in_io.read) }
    end
  end
end

task :jar, [:include_dir] => [:unpack, :clean_jar] do |t, args|
  puts("\n--> Generating JAR file #{TARGET_CLUSTER_JAR}")
  ant.jar :destfile => TARGET_CLUSTER_JAR do
    fileset :dir => TARGET_CLASSES_DIR
    fileset :dir => TARGET_DEPENDENCY_UNPACKED_DIR
    fileset :dir => "#{RedStorm::GEM_PATH}"
    # red_storm.rb and red_storm/* must be in root of jar so that "require 'red_storm'"
    # in bolts/spouts works in jar context
    fileset :dir => TARGET_LIB_DIR do
      exclude :name => "tasks/**"
    end
    if args[:include_dir]
      fileset :dir => CWD do
        args[:include_dir].split(":").each{|dir| include :name => "#{dir}/**/*"}
      end
    end
    manifest do
      attribute :name => "Main-Class", :value => "redstorm.TopologyLauncher"
    end
  end
  puts("\nRedStorm generated JAR file #{TARGET_CLUSTER_JAR}")
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

  puts("\n--> Installing examples into #{DST_EXAMPLES}")
  FileUtils.mkdir(DST_EXAMPLES)
  FileUtils.cp_r(Dir["#{SRC_EXAMPLES}/*"], DST_EXAMPLES)
end

task :copy_red_storm do
  FileUtils.cp_r(REDSTORM_LIB_DIR, TARGET_DIR)
end

task :deps => :setup do
  puts("\n--> Installing dependencies")

  configuration = {
    :repositories => {:clojars => 'http://clojars.org/repo/'},
    :dependencies => [
      "storm:storm:#{INSTALL_STORM_VERSION}",
      "org.jruby:jruby-complete:#{INSTALL_JRUBY_VERSION}"
    ],
    :destination => TARGET_DEPENDENCY_DIR
  }

  installer = PomPomPom::Runner.new(configuration)
  installer.run
end

task :build => :setup do
  # compile the JRuby proxy classes to Java
  build_jruby("#{REDSTORM_LIB_DIR}/red_storm/proxy")

  # compile the generated Java proxy classes
  build_java_dir("#{TARGET_SRC_DIR}")

  # generate the JRuby topology launcher
  build_jruby("#{REDSTORM_LIB_DIR}/red_storm/topology_launcher.rb")

  # compile the JRuby proxy classes
  build_java_dir("#{REDSTORM_JAVA_SRC_DIR}")

  # compile the JRuby proxy classes
  build_java_dir("#{TARGET_SRC_DIR}")
end

task :bundle, [:groups] => :setup do |t, args|
  puts("\n--> Copying gems")

  args.with_defaults(:groups => 'default')
  groups = args[:groups].split(':').map(&:to_sym)
  load_path = []
  Bundler.definition.specs_for(groups).each do |spec|
    unless spec.full_name =~ /^bundler-\d+/
      spec.require_paths.each { |rp| load_path << "#{spec.full_name}/#{rp}" }
      destination_path = "#{RedStorm::GEM_PATH}/#{spec.full_name}"
      unless Dir.exists?(destination_path)
        FileUtils.cp_r(spec.full_gem_path, destination_path)
        # strip the .git directory from git dependencies, it can be huge
        FileUtils.rm_rf("#{destination_path}/.git")
      end
    end
  end
  File.open("#{TARGET_LIB_DIR}/red_storm/setup.rb", 'w') do |io|
    load_path.each do |path|
      io.puts(%|$LOAD_PATH << File.join(RedStorm::GEM_PATH, '#{path}')|)
    end
  end
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
  Dir.chdir(RedStorm::REDSTORM_HOME) do
    argv = []
    argv << '-t' << TARGET_SRC_DIR
    argv << '--verbose'
    argv << '--java'
    argv << '-c' << %("#{TARGET_DEPENDENCY_DIR}/storm-#{INSTALL_STORM_VERSION}.jar")
    argv << '-c' << %("#{TARGET_CLASSES_DIR}")
    argv << source_path
    status =  JRuby::Compiler::compile_argv(argv)
  end
end
