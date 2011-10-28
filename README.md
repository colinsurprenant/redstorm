# Storm JRuby integration

This project is a first try for integrating [JRuby][jruby] in [Storm][storm]. It is currently possible to write **bolts** and **spouts** and also the **topology** creation/launcher in Ruby.

The **Exclamation Topology** and the **Word Count Topology** have been rewritten in Ruby in the `examples/` directory.

## disclaimer/limitations

- No effort yet has been made to produce better/idiomatic Ruby interface. This is as close as possible to the Java interface. Over time I may introduce a more Ruby-esque interface.

- I haven't deployed JRuby topologies into a real Storm cluster yet. Currently all this has been only tested dev mode on the LocalCluster. I will be working on packaging & deployment next.

## dependencies

This has been tested on OSX 10.6.8 using Storm 0.5.3 and JRuby 1.6.4 & 1.6.5

Ruby gems support is provided by `jruby-complete.jar`. By default only `jruby.jar` is included with the JRuby installation but does not support gems.

Until this is better integreted in this project, you **MUST** download `jruby-complete.jar` from http://jruby.org/download and edit the `Rakefile` and `bin/redstorm` to update `JRUBY_JAR` with the path to your `jruby-complete.jar`

## environment

### setup 

**IMPORTANT** these two steps **MUST** be done otherwise nothing will run!

- Edit `Rakefile` and set `JRUBY_JAR` to your `jruby-complete.jar`, see dependencies section
- Edit `bin/redstorm` and set `JRUBY_JAR` to your `jruby-complete.jar`, see dependencies section

Also, if you don't use [RVM][rvm], you should! :P

### build

Building is typically required only once. 

``` sh
$ rake deps
$ rake build
```

- `rake deps` will call the `lein` script to install the required Java libraries in the `storm/lib` directory.
- `rake build` will compile the required Java & Ruby bindings.

## usage

### run

- First create a topology class that implements the `start` method. The *underscore* class filename **MUST** correspond to the *CamelCase* class name.

- Use the `bin/redstorm` launcher with the path to your Ruby topology class file as parameter. See examples below.

### examples

``` sh
$ bin/redstorm examples/ruby_exclamation_topology.rb
$ bin/redstorm examples/ruby_exclamation_topology2.rb
$ bin/redstorm examples/ruby_word_count_topology.rb
```

This next example requires the use of a **Redis** server on `localhost:6379`

``` sh
$ bin/redstorm examples/ruby_redis_word_count_topology
```

## author
Colin Surprenant, [@colinsurprenant][twitter], [colin.surprenant@needium.com][needium], [colin.surprenant@gmail.com][gmail], [http://github.com/colinsurprenant][github]

[needium]: colin.surprenant@needium.com
[gmail]: colin.surprenant@gmail.com
[twitter]: http://twitter.com/colinsurprenant
[github]: http://github.com/colinsurprenant
[rvm]: http://beginrescueend.com/
[storm]: https://github.com/nathanmarz/storm
[jruby]: http://jruby.org/
