# RedStorm v0.6.0 - JRuby on Storm

[![build status](https://secure.travis-ci.org/colinsurprenant/redstorm.png)](http://travis-ci.org/colinsurprenant/redstorm)

RedStorm provides a Ruby DSL using JRuby integration for the [Storm][storm] distributed realtime computation system.

## Documentation

Chances are new versions of RedStorm will introduce changes that will break compatibility or change the developement workflow. To prevent out-of-sync documentation, per version specific documentation are kept in the wiki when necessary. 

### Released gems

- [RedStorm Gem v0.4.x Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.4.x-Documentation)
- [RedStorm Gem v0.5.0 Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.5.0-Documentation)
- [RedStorm Gem v0.5.1 Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.5.1-Documentation)

## Dependencies

Tested on OSX 10.6.8 and Linux 10.04 & 11.10 using Storm 0.7.3 and JRuby 1.6.7.2

## Notes about 1.8/1.9 JRuby compatibility

Up until the upcoming JRuby 1.7, JRuby runs in 1.8 Ruby compatibility mode by default. Unless you have a specific need to run topologies in 1.8 mode, you should use 1.9 mode, which will become the default in JRuby. 

There are two way to have JRuby 1.6.x run in 1.9 mode by default:
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
    
By defaut, a topology will be executed in the **same mode** as the interpreter running the `$ redstorm` command. You can force RedStorm to choose a specific JRuby compatibility mode for the topology execution in local or local cluster using

``` sh
$ redstorm local|cluster [--1.8|--1.9] ...
```

## Installation

- RubyGems

  ``` sh
  $ gem install redstorm
  ```

- Bundler

  ``` ruby
  source :rubygems
  gem "redstorm", "~> 0.6.0"
  ```

## Usage overview

- create a new empty project directory.
- install the [RedStorm gem](http://rubygems.org/gems/redstorm).
- create a subdirectory which will contain your topology code.
- perform the initial setup as described below to build and install dependencies.
- run your topology in local mode and/or on a remote cluster as described below.

### Initial setup

``` sh
$ redstorm install
```

This will basically install all Java jar dependencies in `target/dependency`, generate & compile the Java bindings in `target/classes`.

### Create a topology

Create a subdirectory for your topology code and create your topology class **using the naming convention**:  the *underscore* topology_class_file_name.rb **MUST** correspond to its *CamelCase* class name.

### Gems in your topology

RedStorm requires [Bundler](http://gembundler.com/) **if gems are needed** in your topology. Basically supply a `Gemfile` in the root of your project directory with the gems required in your topology. If you are using Bundler for other gems **you should** group the topology gems in a Bunder group.

1. have Bundler install the gems locally

  ``` sh
  $ bundle install
  ```

2. copy the topology gems into the `target/gems` directory

  ``` sh
  $ redstorm bundle [BUNDLER_GROUP]
  ```

Basically, the `redstorm bundle` command copy the gems specified in the Gemfile (in a specific group if specified) into the `target/gems` directory. In order for the topology to run in a Storm cluster, the fully *installed* gems must be packaged and self-contained into a single JAR file. **Note** you should **NOT** `require 'bundler/setup'` in the topology. 

This has an important consequence: the gems will not be *installed* on the cluster target machines, they are already *installed* in the JAR file. This could possibly lead to problems if the machine used to *install* the gems is of a different architecture than the cluster target machines **and** some of these gems have *native* C/FFI extensions.

### Run in local mode

``` sh
$ redstorm local [--1.8|--1.9]  <path/to/topology_class_file_name.rb>
```

**See examples below** to run examples in local mode or on a production cluster.

### Run on production cluster

1. download and unpack the [Storm distribution](https://github.com/downloads/nathanmarz/storm/storm-0.7.3.zip) locally and **add** the Storm `bin/` directory to your path

2. generate `target/cluster-topology.jar`. This jar file will include your sources directory plus the required dependencies

  ``` sh
  $ redstorm jar <sources_directory1> <sources_directory2> ...
  ```

3. submit the cluster topology jar file to the cluster

  ``` sh
  $ redstorm cluster [--1.8|--1.9]  <path/to/topology_class_file_name.rb>
  ```

The [Storm wiki](https://github.com/nathanmarz/storm/wiki) has instructions on [setting up a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster). You can also [manually submit your topology](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Examples

Install the [example files](https://github.com/colinsurprenant/redstorm/tree/master/examples) in your project. The `examples/` dir will be created in your project root dir.

``` sh
$ redstorm examples
```

All examples using the [simple DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) are located in `examples/simple`. Examples using the standard Java interface are in `examples/native`.

### Local mode

#### Topologies without gems 

``` sh
$ redstorm local --1.9 examples/simple/exclamation_topology.rb
$ redstorm local --1.9 examples/simple/exclamation_topology2.rb
$ redstorm local --1.9 examples/simple/word_count_topology.rb
```

#### Topologies with gems 

For `examples/simple/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis][redis] server running on `localhost:6379`

1. create a `Gemfile`

  ``` ruby
  source :rubygems

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
  $ redstorm local --1.9 examples/simple/redis_word_count_topology.rb
  ```

Using `redis-cli` push words into the `test` list and watch Storm pick them up

### Remote cluster

All examples using the [simple DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) can run in both local or on a remote cluster. The only **native** example compatible with a remote cluster is the [ClusterWordCountTopology](https://github.com/colinsurprenant/redstorm/tree/master/examples/native/cluster_word_count_topology.rb)


#### Topologies without gems 

1. genererate the `target/cluster-topology.jar` and include the `examples/` directory.

  ``` sh
  $ redstorm jar examples
  ```

2. submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

  ``` sh
  $ redstorm cluster --1.9 examples/simple/exclamation_topology.rb
  $ redstorm cluster --1.9 examples/simple/exclamation_topology2.rb
  $ redstorm cluster --1.9 examples/simple/word_count_topology.rb
  ```


#### Topologies with gems 

For `examples/simple/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis][redis] server running on `localhost:6379`

1. create a `Gemfile`

  ``` ruby
  source :rubygems

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
  $ redstorm  jar examples
  ```

4. submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

  ``` sh
  $ redstorm cluster --1.9 examples/simple/redis_word_count_topology.rb
  ```

Using `redis-cli` push words into the `test` list and watch Storm pick them up

The [Storm wiki](https://github.com/nathanmarz/storm/wiki) has instructions on [setting up a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster). You can also [manually submit your topology](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Ruby DSL

[Ruby DSL Documentation](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation)

## RedStorm Development

It is possible to fork the RedStorm project and run local and remote/cluster topologies directly from the project sources without installing the gem. This is a useful setup when contributing to the project.

### Requirements

- JRuby 1.6.7

### Workflow

- fork project and create branch

- install RedStorm required gems

  ```sh
  $ jruby --1.9 -S bundle install
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

- [Tweigeist](https://github.com/colinsurprenant/tweitgeist) - realtime computation of the top trending hashtags on Twitter. [Live Demo](http://tweitgeist.needium.com).

## Author
Colin Surprenant, [@colinsurprenant][twitter], [http://github.com/colinsurprenant][github], colin.surprenant@gmail.com, colin.surprenant@needium.com

## Contributors
Theo Hultberg, https://github.com/iconara

## License
Apache License, Version 2.0. See the LICENSE.md file.

[twitter]: http://twitter.com/colinsurprenant
[github]: http://github.com/colinsurprenant
[rvm]: http://beginrescueend.com/
[storm]: https://github.com/nathanmarz/storm
[jruby]: http://jruby.org/
[ruby-maven]: https://github.com/mkristian/ruby-maven
[redis]: http://redis.io/