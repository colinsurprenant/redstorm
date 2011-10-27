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

``` sh
$ rake storm class=RubyExclamationTopology
$ rake storm class=RubyExclamationTopology2
$ rake storm class=RubyWordCountTopology
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
