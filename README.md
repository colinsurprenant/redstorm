# Storm JRuby integration

This project is a first try for integrating JRuby in Storm. With this it is possible to write **bolts** and **spouts** in Ruby and write the **topology** creation and launcher in Ruby.

The **Exclamation Topology** and the **Word Count Topology** have been rewritten in Ruby in the `examples/` directory.

No effort has been made to produce better/idiomatic Ruby interface. This is as close as possible to the Java interface.

## dependencies

This has been tested on OSX 10.6.8 using Storm 0.5.3 and JRuby 1.6.4

## usage

- Edit `Rakefile` to ajust your `JRUBY_JAR`

### build

``` sh
$ rake deps
$ rake build
```

- `rake deps` will call the `lein` script to install the required Java libraries in the `storm/lib` directory.
- `rake build` will compile the required Java bindings and the Ruby proxy classes and examples.

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
