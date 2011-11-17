# RedStorm v0.2.0 - JRuby on Storm

RedStorm provides the JRuby integration for the [Storm][storm] distributed realtime computation system.

## Changes from 0.1.x

- This release introduces the *simple* DSL. Topology, Spout and Bolt classes can inherit from the SimpleTopoloy, SimpleSpout and SimpleBolt classes which provides a very clean and consise DSL. See `examples/simple`.
- Use the same SimpleTopology class for local development cluster or remote production cluster.
- The `redstorm` command has a new syntax.

## dependencies

This has been tested on OSX 10.6.8 and Linux 10.04 using Storm 0.5.4 and JRuby 1.6.5

## installation
``` sh
$ gem install redstorm
```

## usage overview

- create a new empty project directory.
- install the [RedStorm gem](http://rubygems.org/gems/redstorm).
- create a subdirectory which will contain your sources.
- perform the initial setup as described below to install the dependencies in the `target/` subdir of your project directory.
- run your topology in local mode and/or on a production cluster as described below.

### initial setup

Install RedStom dependencies; from your project root directory execute:

``` sh
$ redstorm install
```

The `install` command will install all Java jars dependencies using [ruby-maven][ruby-maven] in `target/dependency` and generate & compile the Java bindings in `target/classes`

### run in local mode

Create a topology class. The *underscore* topology_class_file_name.rb **MUST** correspond to its *CamelCase* class name.

``` sh
$ redstorm local <path/to/topology_class_file_name.rb>
```

**See examples below** to run examples in local mode or on a production cluster.

### run on production cluster

- generate `target/cluster-topology.jar`. This jar file will include your sources directory plus the required dependencies from the `target/` directory:

``` sh
$ redstorm jar <sources_directory>
```

- submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

``` sh
storm jar ./target/cluster-topology.jar redstorm.TopologyLauncher cluster <path/to/topology_class_file_name.rb>
```

Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## examples

Install the example files into `examples/`:

``` sh
$ redstorm examples
```

All examples using the **simple DSL** are located in `examples/simple`. Examples using the standard Java interface are in `examples/native`.

### local mode

``` sh
$ redstorm local examples/simple/exclamation_topology.rb
$ redstorm local examples/simple/exclamation_topology2.rb
$ redstorm local examples/simple/word_count_topology.rb
```

This next example requires the use of a [Redis][redis] server on `localhost:6379`

``` sh
$ redstorm local examples/simple/redis_word_count_topology.rb
```

Using `redis-cli`, push words into the `test` list and watch Storm pick them up

### production cluster

All examples using the **simple DSL** can also run on a productions cluster. The only **native** example compatible with a production cluster is `examples/native/cluster_word_count_topology.rb`

- genererate the `target/cluster-topology.jar`

``` sh
$ redstorm jar examples
```

- submit the cluster topology jar file to the cluster, assuming you have the Storm distribution installed and the Storm `bin/` directory in your path:

``` sh
storm jar ./target/cluster-topology.jar redstorm.TopologyLauncher ckuster examples/simple/word_count_topology.rb
```

Basically you must follow the [Storm instructions](https://github.com/nathanmarz/storm/wiki) to [setup a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster) and [submit your topology to the cluster](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

## DSL usage

Your project can all be included in a single file containing all spouts, bolts and topology classes or each classes can be in its own file, your choice.

### topology DSL

Normally Storm topology components are assigned and referenced using numeric ids. In the SimpleTopology DSL **ids are optional**. By default the DSL will use the component class name as an implicit symbolic id and bolt source ids can use these implicit ids. The DSL will automatically resolve and assign numeric ids upon topology submission. If two components are of the same class, creating a conflict, then the id can be explicitely defined using either a numeric value, a symbol or a string. Numeric values will be used as-is at the submission, symbols and strings will be resolved and assigned a numeric id at the submission.

``` ruby
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

```
spout spout_class, options
```

- `spout_class` — spout Ruby class
- `options`
  - `:id` — spout explicit id (**default** is spout class name)
  - `:parallelism` — spout parallelism (**default** is 1)

#### bolt statement

```
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
  - `:fields => ["field", ...]` — fieldsGrouping for the given fields
  - `:shuffle` —  shuffleGrouping on the source_id
  - `:global` — globalGrouping on the source_id
  - `:none` — noneGrouping on the source_id
  - `:all` — allGrouping on the source_id
  - `:direct` — directGrouping on the source_id

#### configure statement

```
configure topology_name do |env|
  configuration_field value
  ...
end
```

The `configure` statement is **optional**.

- `topology_name` — alternate topology name (**default** is topology class name)
- `env` — is set to `:local` or `:cluster` for you to set enviroment specific configurations
- `config_attribute` — the Storm Config attribute name. See Storm for complete list
  - `:debug`
  - `:max_task_parallelism` 
  - `:num_workers`
  - `:max_spout_pending`
  -  ...

#### on_submit statement

```
on_submit do |env|
  ...
end
```

The `on_submit` statement is **optional**. Use it to execute code after the topology submission.

- `env` — is set to `:local` or `:cluster`

### spout DSL

```
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

  on_ack do
    ...
  end

  on_fail do
    ...
  end
end
```

#### set statement

```
set spout_attribute => value
```

The `set` statement is **optional**. Use it to set spout specific attributes.

- `spout_attributes`
  - `:is_distributed` — set to `true` for a distributed spout (**default** is `false`)

#### output_fields statement

```
output_fields :field, ...
```

Define the output fields for this spout.

- `:field` — the field name, can be symbol or string.

#### on_send statement

```
on_send options do
  ...
end
```

`on_send` is called periodically by storm to allow the spout to output tuples. When using auto-emit, the block return value will be auto emited. A single value return will be emited as a single-field tuple. An array of values `[a, b]` will be emited as a multiple-fields tuple. An array of arrays `[[a, b], [c, d]]` will be emited as multiple-fields multiple tuples. Array of arrays can be used for single-field tuple too `[[a]]`. When not using auto-emit, the `emit(value, ...)` method can be used to emit a single tuple.

- `:options`
  - `:emit` — set to `false` to disable auto-emit (**default** is `true`)


### bolt DSL

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