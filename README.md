# Storm JRuby integration

## Dependencies

This has been tested on OSX 10.6.8 using Storm 0.5.3 and JRuby 1.6.4

## Usage

- edit Rakefile to ajust your `JRUBY_JAR`

``` sh
$ rake deps
$ rake build
$ rake storm class=RubyExclamationTopology
$ rake storm class=RubyExclamationTopology2
$ rake storm class=RubyWordCountTopology
```
