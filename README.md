# RedStorm v0.5.1 - JRuby on Storm

[![build status](https://secure.travis-ci.org/colinsurprenant/redstorm.png)](http://travis-ci.org/colinsurprenant/redstorm)

RedStorm provides a Ruby DSL using JRuby integration for the [Storm][storm] distributed realtime computation system.

## Documentation

Chances are new versions of RedStorm will introduce changes that will break compatibility or change the developement workflow. To prevent out-of-sync documentation, per version specific documentation are kept in the wiki when necessary. This README reflects the current/master developement state. 

### Released gems

- [RedStorm Gem v0.4.x Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.4.x-Documentation)
- [RedStorm Gem v0.5.0 Documentation](https://github.com/colinsurprenant/redstorm/wiki/RedStorm-Gem-v0.5.0-Documentation)

## Dependencies

Tested on OSX 10.6.8 and Linux 10.04 using Storm 0.6.2 and JRuby 1.6.7

## Notes about 1.8/1.9 JRuby compatibility

Up until the upcoming JRuby 1.7, JRuby runs in 1.8 Ruby compatibility mode by default. Unless you have a specific need to run topologies in 1.8 mode, you should use 1.9 mode, which will become the default in JRuby. Things are a bit tricky with Storm/RedStorm. There are 3 contexts where the Ruby compatibility mode has to be controlled. 

- when installing the topology required gems. the installation path embeds the Ruby version
- when running in local mode or for the submission phase in remote/cluster mode
- when Storm runs the topology in remote/cluster mode

For each of these contexts, 1.9 mode has to be explicitly specified to avoid any problems. All commands/examples below will use the 1.9 compatibility mode. If you want to avoid the explicit --1.9 mode option, using [RVM][rvm] you can compile your JRuby to run in 1.9 mode by default. If you run your topology in remote/cluster mode, you will still need to include some bits of 1.9 options and configuration since in this case JRuby and your topology is run independently by Storm.

## Installation

### Latest released gem
``` sh
$ gem install redstorm
```

### From github master

- clone/fork project

``` sh
$ gem build redstorm.gemspec
$ gem install redstorm-x.y.z.gem
```

## Usage overview

- create a new empty project directory.
- install the [RedStorm gem](http://rubygems.org/gems/redstorm).
- create a subdirectory which will contain your sources.
- perform the initial setup as described below to install the dependencies in the `target/` subdir of your project directory.
- run your topology in local mode and/or on a production cluster as described below.

### Initial setup

- install RedStom dependencies. From your project root directory execute:

  ``` sh
  $ redstorm --1.9 install
  ```

  The `install` command will install all Java jars dependencies using [ruby-maven][ruby-maven] in `target/dependency`, generate & compile the Java bindings in `target/classes` and install gems in `target/gems`.

  ***DON'T PANIC*** it's Maven. The first time you run `$ redstorm --1.9 install` Maven will take a few minutes resolving dependencies and in the end will download and install the dependency jar files.

- create a topology class in your sources subdirectory. The *underscore* topology_class_file_name.rb **MUST** correspond to its *CamelCase* class name.

### Gems in your topology

RedStorm now support [Bundler](http://gembundler.com/) for using gems in your topology. Basically supply a `Gemfile` in the root of your project directory and execute this command to install the gems into the `target/gems` directory. **Note that if you change the Gemfile you must rerun this command**.

  ``` sh
  $ redstorm --1.9 bundle [--gemfile=GEMFILE]
  ```

All `bundle install` command options can be passed as options to `redstorm --1.9 bundle` like `--gemfile=GEMFILE` to specify a Gemfile in an alternate path.

Basically, the `redstorm --1.9 bundle` command installs the *Bundler* and *Rake* gems and all the gems specified in the Gemfile into the `target/gems` directory. The idea is that in order for the topology to run in a Storm cluster, everything, including the fully *installed* gems, must be packaged and self-contained into a single JAR file. This has an important consequence: the gems will not be *installed* on the cluster target machines, they are already *installed* in the JAR file. This could possibly lead to problems if the machine used to *install* the gems is of a different architecture than the cluster target machines **and** some of these gems have *native* C/FFI extensions.

### Run in local mode

``` sh
$ redstorm --1.9 local <path/to/topology_class_file_name.rb>
```

**See examples below** to run examples in local mode or on a production cluster.

### Run on production cluster

- generate `target/cluster-topology.jar`. This jar file will include your sources directory plus the required dependencies from the `target/` directory:

  ``` sh
  $ redstorm --1.9 jar <sources_directory1> <sources_directory2> ...
  ```

- submit the cluster topology jar file to the cluster. Assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

  ``` sh
  storm jar ./target/cluster-topology.jar -Djruby.compat.version=RUBY1_9 redstorm.TopologyLauncher cluster <path/to/topology_class_file_name.rb>
  ```

  Note the **-Djruby.compat.version=RUBY1_9** parameter. 

Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Examples

Install the [example files](https://github.com/colinsurprenant/redstorm/tree/master/examples) in your project. The `examples/` dir will be created in your project root dir.

``` sh
$ redstorm examples
```

All examples using the [simple DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) are located in `examples/simple`. Examples using the standard Java interface are in `examples/native`.

### Local mode

``` sh
$ redstorm --1.9 local examples/simple/exclamation_topology.rb
$ redstorm --1.9 local examples/simple/exclamation_topology2.rb
$ redstorm --1.9 local examples/simple/word_count_topology.rb
```

To run `examples/simple/redis_word_count_topology.rb` you need a [Redis][redis] server running on `localhost:6379`

``` sh
$ redstorm --1.9 bundle --gemfile examples/simple/Gemfile
```

Run the topology in local mode

``` sh
$ redstorm --1.9 local examples/simple/redis_word_count_topology.rb
```

Using `redis-cli`, push words into the `test` list and watch Storm pick them up

### Production cluster

All examples using the [simple DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) can also run on a productions cluster. The only **native** example compatible with a production cluster is the [ClusterWordCountTopology](https://github.com/colinsurprenant/redstorm/tree/master/examples/native/cluster_word_count_topology.rb)

- genererate the `target/cluster-topology.jar` and include the `examples/` directory.

  ``` sh
  $ redstorm --1.9 jar examples
  ```

- submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

  ``` sh
  $ storm jar ./target/cluster-topology.jar -Djruby.compat.version=RUBY1_9 redstorm.TopologyLauncher cluster examples/simple/word_count_topology.rb
  ```

  Note the **-Djruby.compat.version=RUBY1_9** parameter.

- to run `examples/simple/redis_word_count_topology.rb` you need a [Redis][redis] server running on `localhost:6379`

   ``` sh
  $ redstorm --1.9 bundle --gemfile examples/simple/Gemfile
  $ redstorm --1.9 jar examples
  $ storm jar ./target/cluster-topology.jar -Djruby.compat.version=RUBY1_9 redstorm.TopologyLauncher cluster examples/simple/redis_word_count_topology.rb
  ```

  - using `redis-cli`, push words into the `test` list and watch Storm pick them up

Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Ruby DSL

[Ruby DSL Documentation](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation)

## RedStorm Development

It is possible to fork the RedStorm project and run local and remote/cluster topologies directly from the project sources without installing the gem. This is a useful setup when contributing to the project.

### Requirements

- JRuby 1.6.7

### Workflow

- fork project and create branch

- install required gems

  ```sh
  $ jruby --1.9 -S bundle install
  ```

---

- install dependencies in `target/dependencies`

  ```sh
  $ bin/redstorm --1.9 deps
  ```

  **if you modify any of the RedStorm Ruby code** in `lib/red_storm`, you need to run this to refresh code in `target/`.

---

- generate and build Java source into `target/classes`

  ```sh
  $ bin/redstorm --1.9 build
  ```

  **if you modify any of the Java binding code**, you need to run this to rebuild the bindings

---

- run topology in **local** Storm mode

  ```sh
  $ bin/redstorm --1.9 local path/to/topology_class.rb
  ```

  If you only make changes to your topology code, this is the only step you need to repeat to try your updated code.

---

- generate remote cluster topology jar into `target/cluster-topology.jar`, including the `mydir/` directory.

  ```sh
  $ bin/redstorm --1.9 jar mydir otherdir1 otherdir2 ...
  ```

---

- **if you add/change** Gemfile for your topology, install gems in `target/gems`. Alternate gemfile path can be specified using --gemfile=GEMFILE

  ```sh
  $ bin/redstorm --1.9 bundle [--gemfile=GEMFILE]
  ```

  **do not forget** to rerurn `bin/redstorm --1.9 jar ...` to pick up these gems, before submitting your topology on a remote cluster.


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

## Author
Colin Surprenant, [@colinsurprenant][twitter], [http://github.com/colinsurprenant][github], colin.surprenant@gmail.com, colin.surprenant@needium.com

## License
Apache License, Version 2.0. See the LICENSE.md file.

[twitter]: http://twitter.com/colinsurprenant
[github]: http://github.com/colinsurprenant
[rvm]: http://beginrescueend.com/
[storm]: https://github.com/nathanmarz/storm
[jruby]: http://jruby.org/
[ruby-maven]: https://github.com/mkristian/ruby-maven
[redis]: http://redis.io/