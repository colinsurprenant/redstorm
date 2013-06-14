begin
  require 'ant'
rescue
  puts("ERROR: unable to load Ant, make sure Ant is installed, in your PATH and $ANT_HOME is defined properly")
  puts("\nerror detail:\n#{$!}")
  exit(1)
end

require 'jruby/jrubyc'
require 'red_storm/environment'
require 'red_storm/application'

INSTALL_IVY_VERSION = "2.3.0"

task :launch, :env, :ruby_mode, :class_file do |t, args|
  # use ruby mode parameter or default to current interpreter version
  version_token = RedStorm.jruby_mode_token(args[:ruby_mode])

  command = case args[:env]
  when "local"
    RedStorm::Application.local_storm_command(args[:class_file], args[:ruby_mode])
  when "cluster"
    unless File.exist?(TARGET_CLUSTER_JAR)
      puts("error: cluster jar file #{TARGET_CLUSTER_JAR} not found. Generate it using $redstorm jar DIR1 [DIR2, ...]")
      exit(1)
    end
    RedStorm::Application.cluster_storm_command(args[:class_file], args[:ruby_mode])
  end

  puts("launching #{command}")
  unless system(command)
    puts($!)
  end
end

task :clean do
  ant.delete 'dir' => TARGET_DIR
end

task :clean_jar do
  ant.delete 'file' => TARGET_CLUSTER_JAR
end

task :setup do
  puts("\n--> Setting up target directories")
  ant.mkdir 'dir' => TARGET_DIR
  ant.mkdir 'dir' => TARGET_CLASSES_DIR
  ant.mkdir 'dir' => TARGET_DEPENDENCY_DIR
  ant.mkdir 'dir' => TARGET_SRC_DIR
  ant.mkdir 'dir' => TARGET_GEM_DIR
  ant.mkdir 'dir' => TARGET_SPECS_DIR
  ant.path 'id' => 'classpath' do
    fileset 'dir' => TARGET_DEPENDENCY_DIR
    fileset 'dir' => TARGET_CLASSES_DIR
  end
end

task :install => [:deps, :build] do
  puts("\nRedStorm install completed. All dependencies installed in #{TARGET_DIR}")
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
  defaulted_args = {:groups => 'default'}.merge(args.to_hash.delete_if{|k, v| v.to_s.empty?})
  groups = defaulted_args[:groups].split(':').map(&:to_sym)
  Bundler.definition.specs_for(groups).each do |spec|
    next if spec.name == 'bundler'

    # try to avoid infinite recursion
    next if TARGET_GEM_DIR.start_with?(spec.full_gem_path)

    destination_path = "#{TARGET_GEM_DIR}/#{spec.full_name}"
    next if File.directory?(destination_path)

    puts("installing gem #{spec.full_name} into #{destination_path}")
    # copy the actual gem dir
    FileUtils.cp_r(spec.full_gem_path, destination_path)
    # copy the evaluated gemspec into the specifications/ dir (we
    # may not have enough info to reconstruct once we delete the
    # .git directory)
    File.open(File.join(TARGET_SPECS_DIR, File.basename(spec.loaded_from)), 'w'){|f| f.write(spec.to_ruby)}
    # strip the .git directory from git dependencies, it can be huge
    FileUtils.rm_rf("#{destination_path}/.git")
  end
end

namespace :ivy do
  task :download do
    mkdir_p DST_IVY_DIR
    ant.get({
      'src' => "http://repo1.maven.org/maven2/org/apache/ivy/ivy/#{INSTALL_IVY_VERSION}/ivy-#{INSTALL_IVY_VERSION}.jar",
      'dest' => "#{DST_IVY_DIR}/ivy-#{INSTALL_IVY_VERSION}.jar",
      'usetimestamp' => true,
    })
  end

  task :install => :download do
    ant.path 'id' => 'ivy.lib.path' do
      fileset 'dir' => DST_IVY_DIR, 'includes' => '*.jar'
    end

    ant.taskdef({
      'resource' => "org/apache/ivy/ant/antlib.xml",
      'classpathref' => "ivy.lib.path",
      #'uri' => "antlib:org.apache.ivy.ant",
    })
  end
end

task :ivy_config do
  ant.configure 'file' => File.exists?(CUSTOM_IVY_SETTINGS) ? CUSTOM_IVY_SETTINGS : DEFAULT_IVY_SETTINGS
end

task :storm_deps => ["ivy:install", :ivy_config] do
  puts("\n--> Installing Storm dependencies")

  ant.resolve 'file' => File.exists?(CUSTOM_IVY_STORM_DEPENDENCIES) ? CUSTOM_IVY_STORM_DEPENDENCIES : DEFAULT_IVY_STORM_DEPENDENCIES
  ant.retrieve 'pattern' => "#{TARGET_DEPENDENCY_DIR}/storm/[conf]/[artifact]-[revision].[ext]", 'sync' => "true"
end

# task :storm_deps => ["ivy:install", :ivy_config, :storm_deps_only] do
#   puts("\n--> Installing Storm dependencies")
# end

task :topology_deps => ["ivy:install", :ivy_config] do
  puts("\n--> Installing topology dependencies")

  ant.resolve 'file' => File.exists?(CUSTOM_IVY_TOPOLOGY_DEPENDENCIES) ? CUSTOM_IVY_TOPOLOGY_DEPENDENCIES : DEFAULT_IVY_TOPOLOGY_DEPENDENCIES
  ant.retrieve 'pattern' => "#{TARGET_DEPENDENCY_DIR}/topology/[conf]/[artifact]-[revision].[ext]", 'sync' => "true"
end

task :deps => ["ivy:install", :ivy_config, :storm_deps, :topology_deps] do
end

task :jar, [:include_dir] => [:clean_jar] do |t, args|
  puts("\n--> Generating JAR file #{TARGET_CLUSTER_JAR}")

  ant.jar 'destfile' => TARGET_CLUSTER_JAR do
    # rejar all topology jars
    Dir["target/dependency/topology/default/*.jar"].each do |jar|
      puts("Extracting #{jar}")
      zipfileset 'src' => jar, 'includes' => "**/*"
    end
    fileset 'dir' => TARGET_DIR do
      include 'name' => "gems/**"
    end
    fileset 'dir' => TARGET_CLASSES_DIR
    # red_storm.rb and red_storm/* must be in root of jar so that "require 'red_storm'"
    # in bolts/spouts works in jar context
    fileset 'dir' => TARGET_LIB_DIR do
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
      fileset 'dir' => CWD do
        dirs.each{|dir| include 'name' => "#{dir}/**/*"}
      end
    end
    manifest do
      attribute 'name' => "Main-Class", 'value' => "redstorm.TopologyLauncher"
    end
  end
  puts("\nRedStorm generated JAR file #{TARGET_CLUSTER_JAR}")
end

def build_java_dir(source_folder)
  puts("\n--> Compiling Java")
  ant.javac(
    'srcdir' => source_folder,
    'destdir' => TARGET_CLASSES_DIR,
    'classpathref' => 'classpath',
    'source' => "1.7",
    'target' => "1.7",
    'debug' => "yes",
    'includeantruntime' => "no",
    'verbose' => false,
    'listfiles' => true
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
    Dir["#{TARGET_DEPENDENCY_DIR}/storm/default/*.jar"].each do |jar|
      argv << '-c' << %("#{jar}")
    end
    argv << '-c' << %("#{TARGET_CLASSES_DIR}")
    argv << source_path
    status =  JRuby::Compiler::compile_argv(argv)
  end
end
