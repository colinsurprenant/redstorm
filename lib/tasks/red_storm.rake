begin
  require 'ant'
rescue
  puts("error: unable to load Ant, make sure Ant is installed, in your PATH and $ANT_HOME is defined properly")
  puts("\nerror details:\n#{$!}")
  exit(1)
end

require 'jruby/jrubyc'
require 'red_storm/environment'
require 'red_storm/application'

module RedStorm
  INSTALL_IVY_VERSION = "2.3.0"
end

task :launch, :env, :storm_conf, :ruby_mode, :class_file do |t, args|
  # use ruby mode parameter or default to current interpreter version
  version_token = RedStorm.jruby_mode_token(args[:ruby_mode])

  command = case args[:env]
  when "local"
    RedStorm::Application.local_storm_command(args[:class_file], args[:ruby_mode])
  when "cluster"
    unless File.exist?(RedStorm::TARGET_CLUSTER_JAR)
      puts("error: cluster jar file #{RedStorm::TARGET_CLUSTER_JAR} not found. Generate it using $redstorm jar DIR1 [DIR2, ...]")
      exit(1)
    end
    unless File.exist?(args[:storm_conf])
      puts("error: Storm config file #{args[:storm_conf]} not found. Create it or supply alternate path using $redstorm cluster --config STORM_CONFIG_PATH ...")
      exit(1)
    end
    RedStorm::Application.cluster_storm_command(args[:storm_conf], args[:class_file], args[:ruby_mode])
  end

  puts("launching #{command}")
  unless system(command)
    puts($!)
  end
end

task :clean do
  ant.delete 'dir' => RedStorm::TARGET_DIR
end

task :clean_jar do
  ant.delete 'file' => RedStorm::TARGET_CLUSTER_JAR
end

task :setup do
  puts("\n--> Setting up target directories")
  ant.mkdir 'dir' => RedStorm::TARGET_DIR
  ant.mkdir 'dir' => RedStorm::TARGET_CLASSES_DIR
  ant.mkdir 'dir' => RedStorm::TARGET_DEPENDENCY_DIR
  ant.mkdir 'dir' => RedStorm::TARGET_SRC_DIR
  ant.mkdir 'dir' => RedStorm::TARGET_GEM_DIR
  ant.mkdir 'dir' => RedStorm::TARGET_SPECS_DIR
  ant.path 'id' => 'classpath' do
    fileset 'dir' => RedStorm::TARGET_DEPENDENCY_DIR
    fileset 'dir' => RedStorm::TARGET_CLASSES_DIR
  end
end

desc "install dependencies and compile proxy classes"
task :install, [:jvm_version] => [:deps, :build] do |t, args|
  puts("\nRedStorm install completed. All dependencies installed in #{RedStorm::TARGET_DIR}")
end

desc "locally install examples"
task :examples do
  if File.identical?(RedStorm::SRC_EXAMPLES, RedStorm::DST_EXAMPLES)
    STDERR.puts("error: cannot copy examples into itself")
    exit(1)
  end
  if File.exist?(RedStorm::DST_EXAMPLES)
    STDERR.puts("error: directory #{RedStorm::DST_EXAMPLES} already exists")
    exit(1)
  end

  puts("\n--> Installing examples into #{RedStorm::DST_EXAMPLES}")
  FileUtils.mkdir(RedStorm::DST_EXAMPLES)
  FileUtils.cp_r(Dir["#{RedStorm::SRC_EXAMPLES}/*"], RedStorm::DST_EXAMPLES)
end

task :copy_red_storm do
  FileUtils.cp_r(RedStorm::REDSTORM_LIB_DIR, RedStorm::TARGET_DIR)
end

desc "compile JRuby and Java proxy classes"
task :build, [:jvm_version] => [:setup, :copy_red_storm] do |t, args|
  jvm_version = args[:jvm_version].to_s =~ /--(1.\d)/ ? $1 : RedStorm.java_runtime_version

  # compile the JRuby proxy classes to Java
  build_jruby("#{RedStorm::REDSTORM_LIB_DIR}/red_storm/proxy")

  # compile the generated Java proxy classes
  build_java_dir("#{RedStorm::TARGET_SRC_DIR}", jvm_version)

  # generate the JRuby topology launcher
  build_jruby("#{RedStorm::REDSTORM_LIB_DIR}/red_storm/topology_launcher.rb")

  # compile the JRuby proxy classes
  build_java_dir("#{RedStorm::REDSTORM_JAVA_SRC_DIR}", jvm_version)

  # compile the JRuby proxy classes
  build_java_dir("#{RedStorm::TARGET_SRC_DIR}", jvm_version)
end

desc "package topology gems into #{RedStorm::TARGET_GEM_DIR}"
task :bundle, [:groups] => :setup do |t, args|
  require 'bundler'
  defaulted_args = {:groups => 'default'}.merge(args.to_hash.delete_if{|k, v| v.to_s.empty?})
  groups = defaulted_args[:groups].split(':').map(&:to_sym)
  Bundler.definition.specs_for(groups).each do |spec|
    next if spec.name == 'bundler'

    # try to avoid infinite recursion
    next if RedStorm::TARGET_GEM_DIR.start_with?(spec.full_gem_path)

    destination_path = "#{RedStorm::TARGET_GEM_DIR}/#{spec.full_name}"
    next if File.directory?(destination_path)

    puts("installing gem #{spec.full_name} into #{destination_path}")
    # copy the actual gem dir
    FileUtils.cp_r(spec.full_gem_path, destination_path)
    # copy the evaluated gemspec into the specifications/ dir (we
    # may not have enough info to reconstruct once we delete the
    # .git directory)
    File.open(File.join(RedStorm::TARGET_SPECS_DIR, File.basename(spec.loaded_from)), 'w'){|f| f.write(spec.to_ruby)}
    # strip the .git directory from git dependencies, it can be huge
    FileUtils.rm_rf("#{destination_path}/.git")
  end
end

namespace :ivy do
  task :download do
    mkdir_p RedStorm::DST_IVY_DIR
    ant.get({
      'src' => "http://repo1.maven.org/maven2/org/apache/ivy/ivy/#{RedStorm::INSTALL_IVY_VERSION}/ivy-#{RedStorm::INSTALL_IVY_VERSION}.jar",
      'dest' => "#{RedStorm::DST_IVY_DIR}/ivy-#{RedStorm::INSTALL_IVY_VERSION}.jar",
      'usetimestamp' => true,
    })
  end

  task :install => :download do
    ant.path 'id' => 'ivy.lib.path' do
      fileset 'dir' => RedStorm::DST_IVY_DIR, 'includes' => '*.jar'
    end

    ant.taskdef({
      'resource' => "org/apache/ivy/ant/antlib.xml",
      'classpathref' => "ivy.lib.path",
      #'uri' => "antlib:org.apache.ivy.ant",
    })
  end
end

task :ivy_config do
  ant.configure 'file' => File.exists?(RedStorm::CUSTOM_IVY_SETTINGS) ? RedStorm::CUSTOM_IVY_SETTINGS : RedStorm::DEFAULT_IVY_SETTINGS
end

task :storm_deps => ["ivy:install", :ivy_config] do
  puts("\n--> Installing Storm dependencies")

  ant.resolve 'file' => File.exists?(RedStorm::CUSTOM_IVY_STORM_DEPENDENCIES) ? RedStorm::CUSTOM_IVY_STORM_DEPENDENCIES : RedStorm::DEFAULT_IVY_STORM_DEPENDENCIES
  ant.retrieve 'pattern' => "#{RedStorm::TARGET_DEPENDENCY_DIR}/storm/[conf]/[artifact](-[classifier])-[revision].[ext]", 'sync' => "true"
end

task :topology_deps => ["ivy:install", :ivy_config] do
  puts("\n--> Installing topology dependencies")

  ant.resolve 'file' => File.exists?(RedStorm::CUSTOM_IVY_TOPOLOGY_DEPENDENCIES) ? RedStorm::CUSTOM_IVY_TOPOLOGY_DEPENDENCIES : RedStorm::DEFAULT_IVY_TOPOLOGY_DEPENDENCIES
  ant.retrieve 'pattern' => "#{RedStorm::TARGET_DEPENDENCY_DIR}/topology/[conf]/[artifact](-[classifier])-[revision].[ext]", 'sync' => "true"
end

desc "install storm and topology dependencies in #{RedStorm::TARGET_DEPENDENCY_DIR}"
task :deps => ["ivy:install", :ivy_config, :storm_deps, :topology_deps] do
end

desc "generate #{RedStorm::TARGET_CLUSTER_JAR}"
task :jar, [:include_dir] => [:clean_jar] do |t, args|
  puts("\n--> Generating JAR file #{RedStorm::TARGET_CLUSTER_JAR}")

  ant.jar 'destfile' => RedStorm::TARGET_CLUSTER_JAR do
    # rejar all topology jars
    Dir["target/dependency/topology/default/*.jar"].each do |jar|
      puts("Extracting #{jar}")
      zipfileset 'src' => jar, 'includes' => "**/*"
    end
    fileset 'dir' => RedStorm::TARGET_DIR do
      include 'name' => "gems/**"
    end
    fileset 'dir' => RedStorm::TARGET_CLASSES_DIR
    # red_storm.rb and red_storm/* must be in root of jar so that "require 'red_storm'"
    # in bolts/spouts works in jar context
    fileset 'dir' => RedStorm::TARGET_LIB_DIR do
      exclude 'name' => "tasks/**"
    end
    if args[:include_dir]
      dirs = args[:include_dir].split(":")

      # first add any resources/ dir in the tree in the jar root - requirement for ShellBolt multilang resources
      dirs.each do |dir|
        resources_dirs = Dir.glob("#{dir}/**/resources")
        resources_dirs.each do |resources_dir|
          resources_parent = resources_dir.gsub("/resources", "")
          fileset 'dir' => resources_parent do
            include 'name' => "resources/**/*"
          end
        end
      end

      # include complete source dir tree (note we don't care about potential duplicated resources dir)
      fileset 'dir' => RedStorm::CWD do
        dirs.each{|dir| include 'name' => "#{dir}/**/*"}
      end
    end
    manifest do
      attribute 'name' => "Main-Class", 'value' => "redstorm.TopologyLauncher"
    end
  end
  puts("\nRedStorm generated JAR file #{RedStorm::TARGET_CLUSTER_JAR}")
end

def build_java_dir(source_folder, jvm_version)
  puts("\n--> Compiling Java for JVM #{jvm_version}")
  ant.javac(
    'srcdir' => source_folder,
    'destdir' => RedStorm::TARGET_CLASSES_DIR,
    'classpathref' => 'classpath',
    'source' => jvm_version,
    'target' => jvm_version,
    'debug' => "yes",
    'includeantruntime' => "no",
    'verbose' => false,
    'listfiles' => true
  ) do
    # compilerarg :value => "-Xlint:deprecation"
    # compilerarg :value => "-Xlint:unchecked"
  end
end

def build_jruby(source_path)
  puts("\n--> Compiling JRuby")
  Dir.chdir(RedStorm::REDSTORM_HOME) do
    argv = []
    argv << '-t' << RedStorm::TARGET_SRC_DIR
    argv << '--verbose'
    argv << '--java'
    Dir["#{RedStorm::TARGET_DEPENDENCY_DIR}/storm/default/*.jar"].each do |jar|
      argv << '-c' << %("#{jar}")
    end
    argv << '-c' << %("#{RedStorm::TARGET_CLASSES_DIR}")
    argv << source_path
    status =  JRuby::Compiler::compile_argv(argv)
  end
end
