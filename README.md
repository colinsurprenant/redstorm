# RedStorm v0.6.4 - JRuby on Storm

[![build status](https://secure.travis-ci.org/colinsurprenant/redstorm.png)](http://travis-ci.org/colinsurprenant/redstorm)

RedStorm provides a Ruby DSL using JRuby integration for the [Storm](https://github.com/nathanmarz/storm/) distributed realtime computation system.

## Documentation

Chances are new versions of RedStorm will introduce changes that will break compatibility or change the developement workflow. To prevent out-of-sync documentation, per version specific documentation are kept in the wiki when necessary. 

### Released gems

- [RedStorm Gem v0.4.x Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.4.x-Documentation)
- [RedStorm Gem v0.5.0 Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.5.0-Documentation)
- [RedStorm Gem v0.5.1 Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.5.1-Documentation)
- [RedStorm Gem v0.6.3 Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.6.3-Documentation)

## Dependencies

Tested on **OSX 10.8.2** and **Ubuntu Linux 12.04** using **Storm 0.8.1** and **JRuby 1.6.8** and **OpenJDK 7**

## Notes about 1.8/1.9 JRuby compatibility

Up until the upcoming JRuby 1.7, JRuby runs in 1.8 Ruby compatibility mode by default. Unless you have a specific need to run topologies in 1.8 mode, you should use 1.9 mode, which will become the default in JRuby. 

There are two ways to have JRuby 1.6.x run in 1.9 mode by default:
- by setting the JRUBY_OPTS env variable

  ``` sh
  $ export JRUBY_OPTS=--1.9
  ```
- by installing JRuby using RVM with 1.9 mode by default

  ``` sh
  $ rvm install jruby --1.9
  ```

Otherwise, to manually choose the JRuby compatibility mode, this JRuby syntax can be used 

``` sh
$ jruby --1.9 -S redstorm ...
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
    conf.put("topology.worker.childopts", "-Djruby.compat.version=RUBY1_9")

    StormSubmitter.submitTopology("some_topology", conf, builder.createTopology);
  end
end
```

## Installation

- RubyGems

  ``` sh
  $ gem install redstorm
  ```

- Bundler

  ``` ruby
  source "https://rubygems.org"
  gem "redstorm", "~> 0.6.4"
  ```

## Usage overview

- create a project directory.
- install the [RedStorm gem](http://rubygems.org/gems/redstorm).
- create a subdirectory for your topology code.
- perform the initial setup as described below to build and install dependencies.
- run your topology in local mode and/or on a remote cluster as described below.

### Initial setup

``` sh
$ redstorm install
```

or if your default JRuby mode is 1.8 but you want to use 1.9 for your topology development, use

``` sh
$ jruby --1.9 -S redstorm install
```

This will basically install default Java jar dependencies in `target/dependency`, generate & compile the Java bindings in `target/classes`.

### Create a topology

Create a subdirectory for your topology code and create your topology class **using this naming convention**: *underscore* topology_class_file_name.rb **MUST** correspond to its *CamelCase* class name.

### Gems in your topology

RedStorm requires [Bundler](http://gembundler.com/) **if gems are needed** in your topology. Basically supply a `Gemfile` in the root of your project directory with the gems required in your topology. If you are using Bundler also for other gems than those required in the topology **you should** group the topology gems in a Bunder group of your choice.

1. have Bundler install the gems locally

  ``` sh
  $ bundle install
  ```

  or if your default JRuby mode is 1.8 but you want to use 1.9 for your topology development, use

  ``` sh
  $ jruby --1.9 -S bundle install
  ```

2. copy the topology gems into the `target/gems` directory

  ``` sh
  $ redstorm bundle [BUNDLER_GROUP]
  ```

Basically, the `redstorm bundle` command copy the gems specified in the Gemfile (in a specific group if specified) into the `target/gems` directory. In order for the topology to run in a Storm cluster, the fully *installed* gems must be packaged and self-contained into a single jar file. This has an important consequence: the gems will not be *installed* on the cluster target machines, they are already *installed* in the jar file. This **could lead to problems** if the machine used to *install* the gems is of a different architecture than the cluster target machines **and** some of these gems have **C or FFI** extensions.

####IMPORTANT####

Do **not** `require 'bundler/setup'` in the topology. Instead **you need** to require red_storm:
```ruby
require 'red_storm'
```


### Custom Jar dependencies in your topology

By defaut, RedStorm installs Storm and JRuby jars dependencies. If you require custom dependencies, these can be specified by creating the `Dependencies` file in the root of your project. Note that this file overwrites the defaults dependencies so you must also include the Storm and JRuby dependencies. Here's an example of a `Dependencies` file which included the jars required to run the `KafkaTopology` in the examples.

``` ruby
{
  :storm_artifacts => [
    "storm:storm:0.8.1, transitive=true",
  ],
  :topology_artifacts => [
    "org.jruby:jruby-complete:1.6.8, transitive=false",
    "org.scala-lang:scala-library:2.8.0, transitive=false",
    "storm:kafka:0.7.0-incubating, transitive=false",
    "storm:storm-kafka:0.8.0-wip4, transitive=false",
  ],
}
```

Basically the dependendencies are speified as Maven artifacts. There are two sections, the `:storm_artifacts =>` contains the dependencies for running storm in local mode and the `:topology_artifacts =>` are the dependencies specific for your topology. The format is self explainatory and the attribute `transitive=[true|false]` controls the recursive dependencies resolution (using `true`).

The jars repositories can be configured by adding the `ivy/settings.xml` file in the root of your project. For information on the Ivy settings format, see the [Ivy Settings Documentation](http://ant.apache.org/ivy/history/2.2.0/settings.html). I will try my best to eliminate all XML :) but for now I haven't figured how to get rid of this one. For an example Ivy settings file, RedStorm is using the following settings by default:

``` xml
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
$ redstorm local [--1.8|--1.9]  <path/to/topology_class_file_name.rb>
```

By defaut, a topology will be executed in the **same mode** as the interpreter running the `$ redstorm` command. You can force RedStorm to choose a specific JRuby compatibility mode using the [--1.8|--1.9] parameter for the topology execution in local or remote cluster.

**See examples below** to run examples in local mode or on a production cluster.

### Run on production cluster

1. download and unpack the [Storm 0.8.1 distribution](https://github.com/downloads/nathanmarz/storm/storm-0.8.1.zip) locally and **add** the Storm `bin/` directory to your `$PATH`.

2. generate `target/cluster-topology.jar`. This jar file will include your sources directory plus the required dependencies

  ``` sh
  $ redstorm jar <sources_directory1> <sources_directory2> ...
  ```

3. submit the cluster topology jar file to the cluster

  ``` sh
  $ redstorm cluster [--1.8|--1.9]  <path/to/topology_class_file_name.rb>
  ```

  By defaut, a topology will be executed in the **same mode** as the interpreter running the `$ redstorm` command. You can force RedStorm to choose a specific JRuby compatibility mode using the [--1.8|--1.9] parameter for the topology execution in local or remote cluster.

The [Storm wiki](https://github.com/nathanmarz/storm/wiki) has instructions on [setting up a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster). You can also [manually submit your topology](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Examples

Install the [example files](https://github.com/colinsurprenant/redstorm/tree/master/examples) in your project. The `examples/` dir will be created in your project root dir.

``` sh
$ redstorm examples
```

All examples using the [simple DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) are located in `examples/simple`. Examples using the standard Java interface are in `examples/native`.

### Local mode

#### Example topologies without gems 

``` sh
$ redstorm local examples/simple/exclamation_topology.rb
$ redstorm local examples/simple/exclamation_topology2.rb
$ redstorm local examples/simple/word_count_topology.rb
```

#### Example topologies with gems 

For `examples/simple/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis](http://redis.io/) server running on `localhost:6379`

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
  $ redstorm local examples/simple/redis_word_count_topology.rb
  ```

Using `redis-cli` push words into the `test` list and watch Storm pick them up

### Remote cluster

All examples using the [simple DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) can run in both local or on a remote cluster. The only **native** example compatible with a remote cluster is `examples/native/cluster_word_count_topology.rb`.


#### Topologies without gems 

1. genererate the `target/cluster-topology.jar` and include the `examples/` directory.

  ``` sh
  $ redstorm jar examples
  ```

2. submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

  ``` sh
  $ redstorm cluster examples/simple/exclamation_topology.rb
  $ redstorm cluster examples/simple/exclamation_topology2.rb
  $ redstorm cluster examples/simple/word_count_topology.rb
  ```


#### Topologies with gems 

For `examples/simple/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis](http://redis.io/) server running on `localhost:6379`

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
  $ redstorm cluster examples/simple/redis_word_count_topology.rb
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

## RedStorm Development

It is possible to fork the RedStorm project and run local and remote/cluster topologies directly from the project sources without installing the gem. This is a useful setup when contributing to the project.

### Requirements

- JRuby 1.6.8

### Workflow

- fork project and create branch

- install RedStorm required gems

  ```sh
  $ bundle install
  ```

- install dependencies in `target/dependencies`

  ```sh
  $ bin/redstorm deps
  ```

- generate and build Java source into `target/classes`

  ```sh
  $ bin/redstorm build
  ```

  **if you modify any of the RedStorm Ruby code or Java binding code**, you need to run this to refresh code and rebuild the bindings

- follow the normal usage patterns to run the topology in local or remote cluster.

### How to Contribute

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
***Colin Surprenant***, [@colinsurprenant](http://twitter.com/colinsurprenant/), [http://github.com/colinsurprenant/](http://github.com/colinsurprenant/), colin.surprenant@gmail.com, [http://colinsurprenant.com/](http://colinsurprenant.com/)

## Contributors
Theo Hultberg, https://github.com/iconara

## License
Apache License, Version 2.0. See the LICENSE.md file.
