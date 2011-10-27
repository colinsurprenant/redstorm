# Storm JRuby integration

This project is a first try for integrating [JRuby][jruby] in [Storm][storm]. It is currently possible to write **bolts** and **spouts** and also the **topology** creation/launcher in Ruby.

The **Exclamation Topology** and the **Word Count Topology** have been rewritten in Ruby in the `examples/` directory.

## disclaimer/limitations

- No effort yet has been made to produce better/idiomatic Ruby interface. This is as close as possible to the Java interface. Over time I may introduce a more Ruby-esque interface.

- I haven't deployed JRuby topologies into a real Storm cluster yet. Currently all this has been only tested dev mode on the LocalCluster. I will be working on packaging & deployment next.

## dependencies

This has been tested on OSX 10.6.8 using Storm 0.5.3 and JRuby 1.6.4 & 1.6.5

## usage

- Edit `Rakefile` to ajust your `JRUBY_JAR`

- If you don't use [RVM][rvm], you should! :P

### build

``` sh
$ rake deps
$ rake build
```

- `rake deps` will call the `lein` script to install the required Java libraries in the `storm/lib` directory.
- `rake build` will compile the required Java bindings and the Ruby proxy classes and examples.

- When developping I usually a clean before build using:

``` sh
$ rake clean build
```


### run examples

These are the simple examples in `./examples`

``` sh
$ rake storm class=RubyExclamationTopology
$ rake storm class=RubyExclamationTopology2
$ rake storm class=RubyWordCountTopology
```

### using gems

To use gems in your Ruby code, `jruby-complete.jar` is required. By default `jruby.jar` is included with the JRuby installation but does not support gems. You can download `jruby-complete.jar` from http://jruby.org/download

Until this is better integrated, please download `jruby-complete.jar` and edit the `Rakefile` to update `JRUBY_JAR` with the path to your `jruby-complete.jar`

This example uses the **Redis** gem to poll the `test` queue from a Redis server on `localhost:6379` and emits the words into a word count bolt.

``` sh
$ rake storm class=RubyRedisWordCountTopology
```

## Author
Colin Surprenant, [@colinsurprenant][twitter], [colin.surprenant@needium.com][needium], [colin.surprenant@gmail.com][gmail], [http://github.com/colinsurprenant][github]

[needium]: colin.surprenant@needium.com
[gmail]: colin.surprenant@gmail.com
[twitter]: http://twitter.com/colinsurprenant
[github]: http://github.com/colinsurprenant
[rvm]: http://beginrescueend.com/
[storm]: https://github.com/nathanmarz/storm
[jruby]: http://jruby.org/
