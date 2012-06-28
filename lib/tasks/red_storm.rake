require 'ant'
require 'jruby/jrubyc'
require 'pompompom'
require 'red_storm'
 
INSTALL_STORM_VERSION = "0.7.3"
INSTALL_JRUBY_VERSION = "1.6.7.2"

CWD = Dir.pwd
TARGET_DIR = "#{CWD}/target"
TARGET_LIB_DIR = "#{TARGET_DIR}/lib"
TARGET_SRC_DIR = "#{TARGET_DIR}/src"
TARGET_GEM_DIR = "#{TARGET_DIR}/gems/gems"
TARGET_SPECS_DIR = "#{TARGET_DIR}/gems/specifications"
TARGET_CLASSES_DIR = "#{TARGET_DIR}/classes"  
TARGET_DEPENDENCY_DIR = "#{TARGET_DIR}/dependency"
TARGET_DEPENDENCY_UNPACKED_DIR = "#{TARGET_DIR}/dependency-unpacked"
TARGET_CLUSTER_JAR = "#{TARGET_DIR}/cluster-topology.jar"

REDSTORM_JAVA_SRC_DIR = "#{RedStorm::REDSTORM_HOME}/src/main"
REDSTORM_LIB_DIR = "#{RedStorm::REDSTORM_HOME}/lib"

SRC_EXAMPLES = "#{RedStorm::REDSTORM_HOME}/examples"
DST_EXAMPLES = "#{CWD}/examples"

module JavaZip
  import 'java.util.zip.ZipFile'
end

task :launch, :env, :ruby_mode, :class_file do |t, args|
  # use ruby mode parameter or default to current interpreter version
  version_map = {"--1.8" => "RUBY1_8", "--1.9" => "RUBY1_9"}
  version_token = version_map[args[:ruby_mode] || "--#{RedStorm.current_ruby_mode}"]
  
  command = case args[:env]
  when "local"
    "java -Djruby.compat.version=#{version_token} -cp \"#{TARGET_CLASSES_DIR}:#{TARGET_DEPENDENCY_DIR}/*\" redstorm.TopologyLauncher local #{args[:class_file]}"
  when "cluster"
    unless File.exist?(TARGET_CLUSTER_JAR)
      puts("cluster jar file #{TARGET_CLUSTER_JAR} not found. Generate it using $redstorm jar DIR1 [DIR2, ...]")
      exit(1)
    end
    "storm jar #{TARGET_CLUSTER_JAR} -Djruby.compat.version=#{version_token} redstorm.TopologyLauncher cluster #{args[:class_file]}"
  end

  puts("launching #{command}")
  unless system(command)
    puts($!)
  end
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
  ant.mkdir :dir => TARGET_GEM_DIR
  ant.mkdir :dir => TARGET_SPECS_DIR
  ant.path :id => 'classpath' do  
    fileset :dir => TARGET_DEPENDENCY_DIR  
    fileset :dir => TARGET_CLASSES_DIR  
  end  
end

task :install => [:deps, :build] do
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
    fileset :dir => TARGET_DEPENDENCY_UNPACKED_DIR
    fileset :dir => TARGET_DIR do
      include :name => "gems/**"
    end
    fileset :dir => TARGET_CLASSES_DIR
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
    :repositories => {:clojars => 'http://clojars.org/repo/', :sonatype => "http://oss.sonatype.org/content/groups/public/"},
    :dependencies => [
      "storm:storm:#{INSTALL_STORM_VERSION}|type_filter=jar",
      "org.slf4j:slf4j-api:1.5.8|type_filter=jar",
      "org.slf4j:slf4j-log4j12:1.5.8|type_filter=jar",
      "org.jruby:jruby-complete:#{INSTALL_JRUBY_VERSION}|transitive=false,type_filter=jar",
    ],
    :destination => TARGET_DEPENDENCY_DIR
  }

  installer = PomPomPom::Runner.new(configuration)
  installer.run
end

task :build => [:setup, :copy_red_storm] do
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
  require 'bundler'
  args.with_defaults(:groups => 'default')
  groups = args[:groups].split(':').map(&:to_sym)
  Bundler.definition.specs_for(groups).each do |spec|
    unless spec.full_name =~ /^bundler-\d+/
      destination_path = "#{TARGET_GEM_DIR}/#{spec.full_name}"
      unless File.directory?(destination_path)
        puts("installing gem #{spec.full_name} into #{destination_path}")
        # copy the actual gem dir
        FileUtils.cp_r(spec.full_gem_path, destination_path)
        # copy the gemspec into the specifications/ dir
        FileUtils.cp_r(spec.loaded_from, TARGET_SPECS_DIR)
        # strip the .git directory from git dependencies, it can be huge
        FileUtils.rm_rf("#{destination_path}/.git")
      end
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
