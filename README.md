# RedStorm v0.6.6.beta1 - JRuby on Storm

[![build status](https://secure.travis-ci.org/colinsurprenant/redstorm.png)](http://travis-ci.org/colinsurprenant/redstorm)

RedStorm provides a Ruby DSL using JRuby integration for the [Storm](https://github.com/nathanmarz/storm/) distributed realtime computation system.

Like RedStorm? visit us on IRC at #redstorm on freenode

Check also these related projects:

- [redstorm-starter](https://github.com/colinsurprenant/redstorm-starter/)
- [redstorm-benchmark](https://github.com/colinsurprenant/redstorm-benchmark/)

## Documentation

Chances are new versions of RedStorm will introduce changes that will break compatibility or change the developement workflow. To prevent out-of-sync documentation, per version specific documentation are kept [in the wiki](https://github.com/colinsurprenant/redstorm/wiki) when necessary.

## Dependencies

Tested on **OSX 10.8.3** and **Ubuntu Linux 12.10** using **Storm 0.9.0-wip16** and **JRuby 1.7.4** and **OpenJDK 7**

## Installation

- RubyGems

  ``` sh
  $ gem install redstorm
  ```

- Bundler

  ``` ruby
  source "https://rubygems.org"
  gem "redstorm", "~> 0.6.6.beta1"
  ```

## Usage

### Overview

- create a project directory
- install the [RedStorm gem](http://rubygems.org/gems/redstorm)
- create a subdirectory for your topology code
- perform the initial setup as to build and install dependencies

  ``` sh
  $ redstorm install
  ```
- run your topology in local mode

  ``` sh
  $ redstorm local <path/to/topology_class_file_name.rb>
  ```

### Initial setup

``` sh
$ redstorm install
```

This will install default Java jar dependencies in `target/dependency`, generate & compile the Java bindings in `target/classes`.

### Create a topology

Create a subdirectory for your topology code and create your topology class **using this naming convention**: *underscore* topology_class_file_name.rb **MUST** correspond to its *CamelCase* class name.

Here's an example [hello_world_topology.rb](https://github.com/colinsurprenant/redstorm/tree/master/examples/dsl/hello_world_topology.rb)

``` ruby
require 'red_storm'

class HelloWorldSpout < RedStorm::DSL::Spout
  on_init {@words = ["hello", "world"]}
  on_send {@words.shift unless @words.empty?}
end

class HelloWorldBolt < RedStorm::DSL::Bolt
  on_receive :emit => false do |tuple|
    log.info(tuple.getString(0))
  end
end

class HelloWorldTopology < RedStorm::DSL::Topology
  spout HelloWorldSpout do
    output_fields :word
  end

  bolt HelloWorldBolt do
    source HelloWorldSpout, :global
  end
end
```

### Gems in your topology

RedStorm requires [Bundler](http://gembundler.com/) if gems are needed **in your topology**. Supply a `Gemfile` in the root of your project directory with the gems required in your topology. If you are using Bundler also for other gems than those required in the topology **you should** group the topology gems in a Bunder group of your choice.

Note that bundler is only used to help package the gems **prior** to running a topology. Your topology code should **not** use Bundler. With `require "red_storm"` in your topology class file, RedStorm will take care of setting the gems path. Do **not** `require 'bundler/setup'` in the topology.

1. have Bundler install the gems locally

  ``` sh
  $ bundle install
  ```

2. copy the topology gems into the `target/gems` directory

  ``` sh
  $ redstorm bundle [BUNDLER_GROUP]
  ```

3. make sure your topology class has `require "red_storm"`

  ```ruby
  require 'red_storm'
  ```

The `redstorm bundle` command copy the gems specified in the Gemfile (in a specific group if specified) into the `target/gems` directory. In order for the topology to run in a Storm cluster, the fully *installed* gems must be packaged and self-contained into a single jar file. This has an important consequence: the gems will not be *installed* on the cluster target machines, they are already *installed* in the jar file. This **could lead to problems** if the machine used to *install* the gems is of a different architecture than the cluster target machines **and** some of these gems have **C or FFI** extensions.

### Custom Jar dependencies in your topology (XML Warning! :P)

By defaut, RedStorm installs Storm and JRuby jars dependencies into `target/dependency`. RedStorm uses [Ivy](https://ant.apache.org/ivy/) 2.3 to manage dependencies. You can fully control and customize these dependencies.

There are two distinct sets of dependencies: the `storm` dependencies manages the requirements (Storm jars) for the Storm **local mode** runtime. The `topology` dependencies manages the requirements (JRuby jars) for the **topology** runtime.

You can supply custom `storm` and `topology` dependencies by creating `ivy/storm_dependencies.xml` and `ivy/topology_dependencies.xml` files. Below are the current default content for these files:

- `ivy/storm_dependencies.xml`

  ``` xml
  <?xml version="1.0"?>
  <ivy-module version="2.0">
    <info organisation="redstorm" module="storm-deps"/>
    <dependencies>
      <dependency org="storm" name="storm" rev="0.9.0-wip16" conf="default" transitive="true" />
      <override org="org.slf4j" module="slf4j-log4j12" rev="1.6.3"/>
    </dependencies>
  </ivy-module>
  ```

- `ivy/topology_dependencies.xml`

  ``` xml
  <?xml version="1.0"?>
  <ivy-module version="2.0">
    <info organisation="redstorm" module="topology-deps"/>
    <dependencies>
      <dependency org="org.jruby" name="jruby-core" rev="1.7.4" conf="default" transitive="true"/>
    </dependencies>
  </ivy-module>
  ```

The jars repositories can be configured by adding the `ivy/settings.xml` file in the root of your project. For information on the Ivy settings format, see the [Ivy Settings Documentation](http://ant.apache.org/ivy/history/2.3.0/settings.html). Below is the current default:

- `ivy/settings.xml`

  ``` xml
  <?xml version="1.0"?>
  <ivysettings>
    <settings defaultResolver="repositories"/>
    <resolvers>
      <chain name="repositories">
        <ibiblio name="ibiblio" m2compatible="true"/>
        <ibiblio name="maven2" root="http://repo.maven.apache.org/maven2/" m2compatible="true"/>
        <ibiblio name="sonatype" root="http://repo.maven.apache.org/maven2/" m2compatible="true"/>
        <ibiblio name="clojars" root="http://clojars.org/repo/" m2compatible="true"/>
      </chain>
    </resolvers>
  </ivysettings>
  ```

### Run in local mode

``` sh
$ redstorm local <sources_directory_path/topology_class_file_name.rb>
```

note that the topology can also be launched with the following command:

``` sh
$ java -Djruby.compat.version=RUBY1_9 -cp "target/classes:target/dependency/storm/default/*:target/dependency/topology/default/*:<sources_directory_path>" redstorm.TopologyLauncher local <sources_directory_path/topology_class_file_name.rb>
```

**See examples below** to run examples in local mode or on a production cluster.

### Run on production cluster

The Storm distribution is currently required for the cluster topology submission.

1. download and unpack the [Storm 0.9.0-wip16 distribution](https://dl.dropbox.com/u/133901206/storm-0.9.0-wip16.zip) locally

2. add the Storm `bin/` directory to your `$PATH`

3. create `~/.storm/storm.yaml` and add the following

  ```yaml
  nimbus.host: "host_name_or_ip"
  ```

4. generate `target/cluster-topology.jar`. This jar file will include your sources directory plus the required dependencies

  ``` sh
  $ redstorm jar <sources_directory1> <sources_directory2> ...
  ```

5. submit the cluster topology jar file to the cluster

  ``` sh
  $ redstorm cluster <sources_directory/topology_class_file_name.rb>
  ```

  note that the cluster topology jar can also be submitted using the storm command with:

  ``` sh
  $ storm jar target/cluster-topology.jar -Djruby.compat.version=RUBY1_9 redstorm.TopologyLauncher cluster <sources_directory/topology_class_file_name.rb>
  ```

The [Storm wiki](https://github.com/nathanmarz/storm/wiki) has instructions on [setting up a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster). You can also [manually submit your topology](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Examples

Install the [example files](https://github.com/colinsurprenant/redstorm/tree/master/examples) in your project. The `examples/` dir will be created in your project root dir.

``` sh
$ redstorm examples
```

All examples using the [DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) are located in `examples/dsl`. Examples using the standard Java interface are in `examples/native`.

### Local mode

#### Example topologies without gems

``` sh
$ redstorm local examples/dsl/exclamation_topology.rb
$ redstorm local examples/dsl/exclamation_topology2.rb
$ redstorm local examples/dsl/word_count_topology.rb
```

#### Example topologies with gems

For `examples/dsl/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis](http://redis.io/) server running on `localhost:6379`

1. create a `Gemfile`

  ``` ruby
  source "https://rubygems.org"

  group :word_count do
      gem "redis"
  end
  ```

2. install the topology gems

  ``` sh
  $ bundle install
  $ redstorm bundle word_count
  ```

3. run the topology in local mode

  ``` sh
  $ redstorm local examples/dsl/redis_word_count_topology.rb
  ```

Using `redis-cli` push words into the `test` list and watch Storm pick them up

### Remote cluster

All examples using the [DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) can run in both local or on a remote cluster. The only **native** example compatible with a remote cluster is `examples/native/cluster_word_count_topology.rb`.


#### Topologies without gems

1. genererate the `target/cluster-topology.jar` and include the `examples/` directory.

  ``` sh
  $ redstorm jar examples
  ```

2. submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

  ``` sh
  $ redstorm cluster examples/dsl/exclamation_topology.rb
  $ redstorm cluster examples/dsl/exclamation_topology2.rb
  $ redstorm cluster examples/dsl/word_count_topology.rb
  ```


#### Topologies with gems

For `examples/dsl/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis](http://redis.io/) server running on `localhost:6379`

1. create a `Gemfile`

  ``` ruby
  source "https://rubygems.org"

  group :word_count do
      gem "redis"
  end
  ```

2. install the topology gems

  ``` sh
  $ bundle install
  $ redstorm bundle word_count
  ```

3. genererate the `target/cluster-topology.jar` and include the `examples/` directory.

  ``` sh
  $ redstorm jar examples
  ```

4. submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

  ``` sh
  $ redstorm cluster examples/dsl/redis_word_count_topology.rb
  ```

Using `redis-cli` push words into the `test` list and watch Storm pick them up

The [Storm wiki](https://github.com/nathanmarz/storm/wiki) has instructions on [setting up a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster). You can also [manually submit your topology](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Ruby DSL

[Ruby DSL Documentation](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation)

## Multilang ShellSpout & ShellBolt support

Please refer to [Using non JVM languages with Storm](https://github.com/nathanmarz/storm/wiki/Using-non-JVM-languages-with-Storm) for the complete information on Multilang & shelling in Storm.

In RedStorm *ShellSpout* and *ShellBolt* are supported using the following construct in the topology definition:

``` ruby
bolt JRubyShellBolt, ["python", "splitsentence.py"] do
  output_fields "word"
  source SimpleSpout, :shuffle
end
```

- `JRubyShellBolt` must be used for a *ShellBolt* and the array argument `["python", "splitsentence.py"]` are the arguments to the class constructor and are the *commands* to the *ShellBolt*.

- The directory containing the topology class **must** contain a `resources/` directory with all the shell files.

See the [shell topology example](https://github.com/colinsurprenant/redstorm/tree/master/examples/shell)

## Transactional and LinearDRPC topologies

Despite the fact that both transactional and linear DRPC topologies are now [deprecated as of Storm 0.8.1](https://github.com/nathanmarz/storm/blob/master/CHANGELOG.md) work on these has been merged in RedStorm 0.6.5. Lots of the work done on this is required toward Storm Trident topologies. Documentation and examples for transactional and linear DRPC topologies will be added shorty.

## Known issues

- SnakeYAML conflict between Storm and JRuby

  See [issue](https://github.com/colinsurprenant/redstorm/issues/78). This is a classic Java world jar conflict. Storm 0.9.0 uses snakeyaml 1.9 and JRuby 1.7.x uses snakeyaml 1.11. If you try to use YAML serialization in your topology it will crash with an exception. This problem is easy to solve when running topologies in **local** mode, simply override in the storm dependencies with the correct jar version. You can do this be creating a custom storm dependencies:

  - `ivy/storm_dependencies.xml`

    ``` xml
    <?xml version="1.0"?>
    <ivy-module version="2.0">
      <info organisation="redstorm" module="storm-deps"/>
      <dependencies>
        <dependency org="storm" name="storm" rev="0.9.0-wip16" conf="default" transitive="true" />
        <override org="org.slf4j" module="slf4j-log4j12" rev="1.6.3"/>
        <override org="org.yaml" module="snakeyaml" rev="1.11"/>
      </dependencies>
    </ivy-module>
    ```

  In remote **cluster** mode you will have to update snakeyaml manually or with your favorite deployment/provisioning tool.

## RedStorm Development

It is possible to fork the RedStorm project and run local and remote/cluster topologies directly from the project sources without installing the gem. This is a useful setup when contributing to the project.

### Requirements

- JRuby 1.7.4

### Workflow

- fork project and create branch

- install RedStorm required gems

  ```sh
  $ bundle install
  ```

- install dependencies in `target/dependencies`

  ```sh
  $ bundle exec redstorm deps
  ```

- generate and build Java source into `target/classes`

  ```sh
  $ bundle exec redstorm build
  ```

  **if you modify any of the RedStorm Ruby code or Java binding code**, you need to run this to refresh code and rebuild the bindings

- follow the normal usage patterns to run the topology in local or remote cluster.

  ```sh
  $ bundle exec redstorm bundle ...
  $ bundle exec redstorm local ...
  $ bundle exec redstorm jar ...
  $ bundle exec redstorm cluster ...
  ```

### Remote cluster testing

Vagrant & Chef configuration to create a single node test Storm cluster is available in https://github.com/colinsurprenant/redstorm/tree/master/vagrant/

## Notes about 1.8/1.9 JRuby compatibility

Ruby 1.9 is the default runtime mode in JRuby 1.7.x

If you require Ruby 1.8 support, there are two ways to have JRuby run in 1.8 runtime mode:

- by setting the JRUBY_OPTS env variable

  ``` sh
  $ export JRUBY_OPTS=--1.8
  ```

- by using the --1.8 option

  ``` sh
  $ jruby --1.8 -S redstorm ...
  ```

By defaut, a topology will be executed in the **same mode** as the interpreter running the `$ redstorm` command. You can force RedStorm to choose a specific JRuby compatibility mode using the [--1.8|--1.9] parameter for the topology execution in local or remote cluster.

``` sh
$ redstorm local|cluster [--1.8|--1.9] ...
```

If you are **not using the DSL** and only using the proxy classes (like in `examples/native`) you will need to manually set the JRuby version in the Storm `Backtype::Config` object like this:

``` ruby
class SomeTopology
  RedStorm::Configuration.topology_class = self

  def start(base_class_path, env)
    builder = TopologyBuilder.new
    builder.setSpout ...
    builder.setBolt ...

    conf = Backtype::Config.new
    conf.put("topology.worker.childopts", "-Djruby.compat.version=RUBY1_8")

    StormSubmitter.submitTopology("some_topology", conf, builder.createTopology);
  end
end
```

### How to contribute

Fork the project, create a branch and submit a pull request.

Some ways you can contribute:

- by reporting bugs using the issue tracker
- by suggesting new features using the issue tracker
- by writing or editing documentation
- by writing specs
- by writing code
- by refactoring code
- ...

## Projects using RedStorm

If you want to list your RedStorm project here, contact me.

- [Tweigeist](https://github.com/colinsurprenant/tweitgeist) - realtime computation of the top trending hashtags on Twitter. See [Live Demo](http://tweitgeist.colinsurprenant.com/).

## Author
**Colin Surprenant**, http://github.com/colinsurprenant/, [@colinsurprenant](http://twitter.com/colinsurprenant/), colin.surprenant@gmail.com, http://colinsurprenant.com/

## Contributors
- Theo Hultberg, https://github.com/iconara
- Paul Bergeron, https://github.com/dinedal
- Phil Pirozhkov, https://github.com/pirj
- Evan Broderm, https://github.com/ebroder
- Shay Elkin, https://github.com/shayel
- adsummos, https://github.com/adsummos

## License
Apache License, Version 2.0. See the LICENSE.md file.
