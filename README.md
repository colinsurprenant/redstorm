# RedStorm v0.1.1 - JRuby on Storm

RedStorm provides the JRuby integration for the [Storm][storm] distributed realtime computation system.

## disclaimer/limitations

The current Ruby interface is **very** similar to the Java interface. A more idiomatic Ruby interface will be be addded, as I better understand the various usage patterns.

## dependencies

This has been tested on OSX 10.6.8 and Linux 10.04 using Storm 0.5.4 and JRuby 1.6.5

## installation
``` sh
$ gem install redstorm
```

## usage

The currently supported usage pattern is to start your new Storm project in an empty directory, install the RedStorm gem and follow the steps below. There is no layout constrains for your project. The `target/` directory will be created by RedStorm in the root of your project.

### initial setup

Install RedStom dependencies; from your project root directory execute:

``` sh
$ redstorm install
```

The `install` command will install all Java jars dependencies using [ruby-maven][ruby-maven] in `target/dependency` and generate & compile the Java bindings in `target/classes`

### run in local mode

Create a topology class that implements the `start` method. The *underscore* topology_class_file_name.rb **MUST** correspond to its *CamelCase* class name.

``` sh
$ redstorm topology_class_file_name.rb
```

**See examples below** to run examples in local mode or on a production cluster.

### run on production cluster

- generate `target/cluster-topology.jar`. This jar file will include everything in your project directory plus the required dependencies from the `target/` directory:

``` sh
$ redstorm jar
```

- submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

``` sh
storm jar ./target/cluster-topology.jar redstorm.TopologyLauncher topology_class_file_name.rb
```

Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).


## examples

Install the example files into `examples/`:

``` sh
$ redstorm examples
```

### local mode

``` sh
$ redstorm examples/local_exclamation_topology.rb
$ redstorm examples/local_exclamation_topology2.rb
$ redstorm examples/local_word_count_topology.rb
```

This next example requires the use of a [Redis][redis] server on `localhost:6379`

``` sh
$ redstorm examples/local_redis_word_count_topology.rb
```

Using `redis-cli`, push words into the `test` list and watch Storm pick them up

### production cluster

The only example compatible with a production cluster is `examples/cluster_word_count_topology.rb`

- genererate the `target/cluster-topology.jar`

``` sh
$ redstorm jar
```

- submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

``` sh
storm jar ./target/cluster-topology.jar redstorm.TopologyLauncher examples/cluster_word_count_topology.rb
```

Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).


## author
Colin Surprenant, [@colinsurprenant][twitter], [colin.surprenant@needium.com][needium], [colin.surprenant@gmail.com][gmail], [http://github.com/colinsurprenant][github]

## license
Apache License, Version 2.0. See the LICENSE.md file.

[needium]: colin.surprenant@needium.com
[gmail]: colin.surprenant@gmail.com
[twitter]: http://twitter.com/colinsurprenant
[github]: http://github.com/colinsurprenant
[rvm]: http://beginrescueend.com/
[storm]: https://github.com/nathanmarz/storm
[jruby]: http://jruby.org/
[ruby-maven]: https://github.com/mkristian/ruby-maven
[redis]: http://redis.io/