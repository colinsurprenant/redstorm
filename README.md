# RedStorm v0.4.0 - JRuby on Storm

[![build status](https://secure.travis-ci.org/colinsurprenant/redstorm.png)](http://travis-ci.org/colinsurprenant/redstorm)

RedStorm provides the JRuby integration for the [Storm][storm] distributed realtime computation system.

## Dependencies

This has been tested on OSX 10.6.8 and Linux 10.04 using Storm 0.6.2 and JRuby 1.6.6

## Installation
``` sh
$ gem install redstorm
```

## Usage overview

- create a new empty project directory.
- install the [RedStorm gem](http://rubygems.org/gems/redstorm).
- create a subdirectory which will contain your sources.
- perform the initial setup as described below to install the dependencies in the `target/` subdir of your project directory.
- run your topology in local mode and/or on a production cluster as described below.

### Initial setup

- install RedStom dependencies; from your project root directory execute:

``` sh
$ redstorm install
```

The `install` command will install all Java jars dependencies using [ruby-maven][ruby-maven] in `target/dependency` and generate & compile the Java bindings in `target/classes`

***DON'T PANIC*** it's Maven. The first time you run `$ redstorm install` Maven will take a few minutes resolving dependencies and in the end will download and install the dependency jar files.

- create a topology class. The *underscore* topology_class_file_name.rb **MUST** correspond to its *CamelCase* class name.

### Gems

Until this is better integrated, you can use **gems** in local mode and on a production cluster:

- **local mode**: simply install your gems the usual way, they will be picked up when run in local mode.

- **production cluster**: install your gem in the `target/gems` folder using:

```sh
gem install <the gem> --install-dir target/gems/ --no-ri --no-rdoc
```

### Run in local mode

``` sh
$ redstorm local <path/to/topology_class_file_name.rb>
```

**See examples below** to run examples in local mode or on a production cluster.

### Run on production cluster

- generate `target/cluster-topology.jar`. This jar file will include your sources directory plus the required dependencies from the `target/` directory:

``` sh
$ redstorm jar <sources_directory>
```

- submit the cluster topology jar file to the cluster. Assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

``` sh
storm jar ./target/cluster-topology.jar redstorm.TopologyLauncher cluster <path/to/topology_class_file_name.rb>
```

Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## Examples

Install the [example files](https://github.com/colinsurprenant/redstorm/tree/master/examples) in your project. The `examples/` dir will be created in your project root dir.

``` sh
$ redstorm examples
```

All examples using the **simple DSL** are located in `examples/simple`. Examples using the standard Java interface are in `examples/native`.

### Local mode

``` sh
$ redstorm local examples/simple/exclamation_topology.rb
$ redstorm local examples/simple/exclamation_topology2.rb
$ redstorm local examples/simple/word_count_topology.rb
```

This next example requires the use of the [Redis Gem](https://github.com/ezmobius/redis-rb) and a [Redis][redis] server running on `localhost:6379`

``` sh
$ redstorm local examples/simple/redis_word_count_topology.rb
```

Using `redis-cli`, push words into the `test` list and watch Storm pick them up

### Production cluster

All examples using the **simple DSL** can also run on a productions cluster. The only **native** example compatible with a production cluster is the [ClusterWordCountTopology](https://github.com/colinsurprenant/redstorm/tree/master/examples/native/cluster_word_count_topology.rb)

- genererate the `target/cluster-topology.jar` and include the `examples/` directory.

``` sh
$ redstorm jar examples
```

- submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

``` sh
$ storm jar ./target/cluster-topology.jar redstorm.TopologyLauncher cluster examples/simple/word_count_topology.rb
```

- to run `examples/simple/redis_word_count_topology.rb` you need a [Redis][redis] server running on `localhost:6379` and the Redis gem in `target/gems` using:

```sh
gem install redis --install-dir target/gems/ --no-ri --no-rdoc
```

- generate jar and submit:

``` sh
$ redstorm jar examples
$ storm jar ./target/cluster-topology.jar redstorm.TopologyLauncher cluster examples/simple/redis_word_count_topology.rb
```

- using `redis-cli`, push words into the `test` list and watch Storm pick them up


Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## DSL usage

Your project can be created in a single file containing all spouts, bolts and topology classes or each classes can be in its own file, your choice. There are [many examples](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple) for the *simple* DSL.

The DSL uses a **callback metaphor** to attach code to the topology/spout/bolt execution contexts using `on_*` DSL constructs (ex.: on_submit, on_send, ...). When using `on_*` you can attach you code in 3 different ways:

- using a code block

```ruby
on_receive (:ack => true, :anchor => true) {|tuple| do_something_with(tuple)}

on_receive :ack => true, :anchor => true do |tuple| 
  do_something_with(tuple)
end
```

- defining the corresponding method

```ruby
on_receive :ack => true, :anchor => true 
def on_receive(tuple)
  do_something_with(tuple)
end
```

- defining an arbitrary method

```ruby
on_receive :my_method, :ack => true, :anchor => true 
def my_method(tuple)
  do_something_with(tuple)
end
```

The [example SplitSentenceBolt](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/split_sentence_bolt.rb) shows the 3 different coding style.

### Topology DSL

Normally Storm topology components are assigned and referenced using numeric ids. In the SimpleTopology DSL **ids are optional**. By default the DSL will use the component class name as an implicit symbolic id and bolt source ids can use these implicit ids. The DSL will automatically resolve and assign numeric ids upon topology submission. If two components are of the same class, creating a conflict, then the id can be explicitly defined using either a numeric value, a symbol or a string. Numeric values will be used as-is at topology submission while symbols and strings will be resolved and assigned a numeric id.

```ruby
require 'red_storm'

class MyTopology < RedStorm::SimpleTopology
  
  spout spout_class, options 
  
  bolt bolt_class, options do
    source source_id, grouping
    ...
  end
  
  configure topology_name do |env|
    config_attribute value
    ...
  end

  on_submit do |env|
    ...
  end
end
```

#### spout statement

```ruby
spout spout_class, options
```

- `spout_class` — spout Ruby class
- `options`
  - `:id` — spout explicit id (**default** is spout class name)
  - `:parallelism` — spout parallelism (**default** is 1)

#### bolt statement

```ruby
bolt bolt_class, options do
  source source_id, grouping
  ...
end
```

- `bolt_class` — bolt Ruby class
- `options`
  - `:id` — bolt explicit id (**default** is bolt class name)
  - `:parallelism` — bolt parallelism (**default** is 1)
- `source_id` — source id reference. can be the source class name if unique or the explicit id if defined
- `grouping`
  - `:fields => ["field", ...]` — fieldsGrouping using fields on the source_id
  - `:shuffle` —  shuffleGrouping on the source_id
  - `:global` — globalGrouping on the source_id
  - `:none` — noneGrouping on the source_id
  - `:all` — allGrouping on the source_id
  - `:direct` — directGrouping on the source_id

#### configure statement

```ruby
configure topology_name do |env|
  configuration_field value
  ...
end
```

The `configure` statement is **required**.

- `topology_name` — alternate topology name (**default** is topology class name)
- `env` — is set to `:local` or `:cluster` for you to set enviroment specific configurations
- `config_attribute` — the Storm Config attribute name. See Storm for complete list. The attribute name correspond to the Java setter method, without the "set" prefix and the suffix converted from CamelCase to underscore. Ex.: `setMaxTaskParallelism` is `:max_task_parallelism`.
  - `:debug`
  - `:max_task_parallelism` 
  - `:num_workers`
  - `:max_spout_pending`
  -  ...

#### on_submit statement

```ruby
on_submit do |env|
  ...
end
```

The `on_submit` statement is **optional**. Use it to execute code after the topology submission.

- `env` — is set to `:local` or `:cluster`

For example, you can use `on_submit` to shutdown the LocalCluster after some time. The LocalCluster instance is available usign the `cluster` method. 

```ruby
on_submit do |env|
  if env == :local
    sleep(5)
    cluster.shutdown
  end
end
```

#### Examples

- [ExclamationTopology](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/exclamation_topology.rb)
- [ExclamationTopology2](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/exclamation_topology2.rb)
- [WordCountTopology](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/word_count_topology.rb)
- [RedisWordCountTopology](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/redis_word_count_topology.rb)

### Spout DSL

```ruby
require 'red_storm'

class MySpout < RedStorm::SimpleSpout
  set spout_attribute => value
  ...

  output_fields :field, ...

  on_send options do
    ...
  end

  on_init do
    ...
  end

  on_close do
    ...
  end

  on_ack do |msg_id|
    ...
  end

  on_fail do |msg_id|
    ...
  end
end
```

#### set statement

```ruby
set spout_attribute => value
```

The `set` statement is **optional**. Use it to set spout specific attributes.

- `spout_attributes`
  - `:is_distributed` — set to `true` for a distributed spout (**default** is `false`)

#### output_fields statement

```ruby
output_fields :field, ...
```

Define the output fields for this spout.

- `:field` — the field name, can be symbol or string.

#### on_send statement

```ruby
on_send options do
  ...
end
```

`on_send` relates to the Java spout `nextTuple` method and is called periodically by storm to allow the spout to output a tuple. When using auto-emit (default), the block return value will be auto emited. A single value return will be emited as a single-field tuple. An array of values `[a, b]` will be emited as a multiple-fields tuple. Normally a spout [should only output a single tuple per on_send invocation](https://groups.google.com/forum/#!topic/storm-user/SGwih7vPiDE/discussion).

- `:options`
  - `:emit` — set to `false` to disable auto-emit (**default** is `true`)

#### on_init statement

```ruby
on_init do
  ...
end
```

`on_init` relates to the Java spout `open` method. When `on_init` is called, the `config`, `context` and `collector` are set to return the Java spout config `Map`, `TopologyContext` and `SpoutOutputCollector`.

#### on_close statement

```ruby
on_close do
  ...
end
```

`on_close` relates to the Java spout `close` method. 

#### on_ack statement

```ruby
on_ack do |msg_id|
  ...
end
```

`on_ack` relates to the Java spout `ack` method. 

#### on_fail statement

```ruby
on_fail do |msg_id|
  ...
end
```

`on_fail` relates to the Java spout `fail` method. 

#### Examples

- [RandomSentenceSpout](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/random_sentence_spout.rb)
- [RedisWordSpout](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/redis_word_count_topology.rb)

### Bolt DSL

```ruby
require 'red_storm'

class MyBolt < RedStorm::SimpleBolt
  output_fields :field, ...

  on_receive options do
    ...
  end

  on_init do
    ...
  end

  on_close do
    ...
  end
end
```

#### on_receive statement

```ruby
on_receive options do
  ...
end
```

`on_receive` relates to the Java bolt `execute` method and is called upon tuple reception by Storm. When using auto-emit, the block return value will be auto emited. A single value return will be emited as a single-field tuple. An array of values `[a, b]` will be emited as a multiple-fields tuple. An array of arrays `[[a, b], [c, d]]` will be emited as multiple-fields multiple tuples. When not using auto-emit, the `unanchored_emit(value, ...)` and `anchored_emit(tuple, value, ...)` method can be used to emit a single tuple. When using auto-anchor (disabled by default) the sent tuples will be anchored to the received tuple. When using auto-ack (disabled by default) the received tuple will be ack'ed after emitting the return value. When not using auto-ack, the `ack(tuple)` method can be used to ack the tuple. 

Note that setting auto-ack and auto-anchor is possible **only** when auto-emit is enabled.

- `:options`
  - `:emit` — set to `false` to disable auto-emit (**default** is `true`)
  - `:ack`  — set to `true` to enable auto-ack (**default** is `false`)
  - `:anchor`  — set to `true` to enable auto-anchor (**default** is `false`)

#### on_init statement

```ruby
on_init do
  ...
end
```

`on_init` relates to the Java bolt `prepare` method. When `on_init` is called, the `config`, `context` and `collector` are set to return the Java spout config `Map`, `TopologyContext` and `SpoutOutputCollector`.

#### on_close statement

```ruby
on_close do
  ...
end
```

`on_close` relates to the Java bolt `cleanup` method. 

#### Examples

- [ExclamationBolt](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/exclamation_bolt.rb)
- [SplitSentenceBolt](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/split_sentence_bolt.rb)
- [WordCountBolt](https://github.com/colinsurprenant/redstorm/tree/master/examples/simple/word_count_bolt.rb)

## Development

### Requirements

- JRuby 1.6.6
- rake gem ~> 0.9.2.2
- ruby-maven gem ~> 3.0.3.0.28.5
- rspec gem ~> 2.8.0

### Contribute

Fork the project, create a branch and submit a pull request.

Some ways you can contribute:

- by reporting bugs using the issue tracker
- by suggesting new features using the issue tracker
- by writing or editing documentation
- by writing specs
- by writing code
- by refactoring code
- ...

### Workflow

- fork project
- create branch
- install dependencies in `target/dependencies`

```sh
$ rake deps
```

- generate and build Java source into `target/classes`

```sh
$ rake build
```

- run topology in local dev cluster

```sh
$ bin/redstorm local path/to/topology_class.rb
```

- generate remote cluster topology jar into `target/cluster-topology.jar`, including the `examples/` directory.

```sh
$ rake jar['examples']
```

## Author
Colin Surprenant, [@colinsurprenant][twitter], [colin.surprenant@needium.com][needium], [colin.surprenant@gmail.com][gmail], [http://github.com/colinsurprenant][github]

## License
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