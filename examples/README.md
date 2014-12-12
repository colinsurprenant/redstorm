# RedStorm Examples - JRuby on Storm

[![Gem Version](https://badge.fury.io/rb/redstorm.png)](http://badge.fury.io/rb/redstorm)
[![build status](https://secure.travis-ci.org/colinsurprenant/redstorm.png)](http://travis-ci.org/colinsurprenant/redstorm)
[![Code Climate](https://codeclimate.com/github/colinsurprenant/redstorm.png)](https://codeclimate.com/github/colinsurprenant/redstorm)
[![Coverage Status](https://coveralls.io/repos/colinsurprenant/redstorm/badge.png?branch=master)](https://coveralls.io/r/colinsurprenant/redstorm?branch=master)

RedStorm provides a Ruby DSL using JRuby integration for the [Storm](https://github.com/nathanmarz/storm/) distributed realtime computation system.

## Installing the Examples

Install the [example files](https://github.com/colinsurprenant/redstorm/tree/master/examples) in your project. The `examples/` dir will be created in your project root dir.

``` sh
$ redstorm examples
```

All examples using the [DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) are located in `examples/dsl`. Examples using the standard Java interface are in `examples/native`.

## Running the Examples
### Local mode

#### Example topologies without gems

``` sh
$ redstorm local examples/dsl/exclamation_topology.rb
$ redstorm local examples/dsl/exclamation_topology2.rb
$ redstorm local examples/dsl/word_count_topology.rb
```

#### Example topologies with gems

For `examples/dsl/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis](http://redis.io/) server running on `localhost:6379`

1. create a `Gemfile`

  ``` ruby
  source "https://rubygems.org"

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
  $ redstorm local examples/dsl/redis_word_count_topology.rb
  ```

Using `redis-cli` push words into the `test` list and watch Storm pick them up

#### Example Kafka Topology
The provided example Kafka Topology requires additional Java dependencies, and also requires you to be running a Kafka cluster. For this tutorial, we will be running Kafka in local mode.

##### Install dependencies
First, you will need add some additional dependencies to the ``ivy/topology_dependencies.xml`` file. Place the following dependencies (also described in ``examples/dsl/kafka_topology.rb``) in ``ivy/topology_dependencies.xml``:
```xml
<dependencies>
	.
	.
	<dependency org="org.scala-lang" name="scala-library" rev="2.10.1" conf="default" transitive="false" />
  <dependency org="org.apache.kafka" name="kafka_2.10" rev="0.8.1.1" conf="default" transitive="false" />
  <dependency org="org.apache.storm" name="storm-kafka" rev="0.9.3" conf="default" transitive="true" />
  <dependency org="com.yammer.metrics" name="metrics-core" rev="2.2.0"/>
  <dependency org="com.google.guava" name="guava" rev="16.0.1"/>
  <exclude org="org.slf4j" module="slf4j-log4j12" />
	.
	.
</dependency>
```

Then, install the dependencies and rebuild RedStorm:

  ``` sh
  $ redstorm deps
  $ redstorm build
  ```

##### Download and start Apache Kafka
Next, you will need to download Apache Kafka. You can find the download page [here](https://kafka.apache.org/downloads.html). For this tutorial, make sure to download the kafka_2.9.2-0.8.1.1 release.

After downloading Kafka, you will need to start the included Zookeeper server and Kafka server. You can find the original instructions for the following steps [here](https://kafka.apache.org/documentation.html#quickstart).

From the Kafka directory, start the Zookeeper server:

  ``` sh
  $ bin/zookeeper-server-start.sh config/zookeeper.properties
  ```

Then, start the Kafka server:

  ``` sh
  $ bin/kafka-server-start.sh config/server.properties
  ```

  Next, you'll need to create a Kafka topic called 'test':

  ``` sh
  $ bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic test
  ```

Now for the fun part. What we're going to do is start a command line Kafka producer, where you can type in messages and send them to Kafka. Then, we're going to fire up the Storm topology, and watch as the messages from Kafka are processed.

First, start the Kafka console producer:

  ``` sh
  $ bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test 
  ```

Then, open up another terminal side-by-side with the one containing the Kafka producer. Change directories to your RedStorm project, and start the KafkaTopology:

  ``` sh
  $ redstorm local examples/dsl/kafka_topology.rb
  ```

Note that this will run for two minutes, during which you'll be able to type messages into the Kafka console and see them processed within Storm.

Finally, switch to the Kafka console, and begin typing in some messages:

  ``` sh
  Hello World!
  From Kafka to Redstorm
  ```

If you've set up everything correctly, you should now see the messages come into the Storm console and get split into words. Cool!

### Remote cluster

All examples using the [DSL](https://github.com/colinsurprenant/redstorm/wiki/Ruby-DSL-Documentation) can run in both local or on a remote cluster. The only **native** example compatible with a remote cluster is `examples/native/cluster_word_count_topology.rb`.


#### Topologies without gems

1. genererate the `target/cluster-topology.jar` and include the `examples/` directory

  ``` sh
  $ redstorm jar examples
  ```

2. submit the cluster topology jar file to the cluster

  ``` sh
  $ redstorm cluster examples/dsl/exclamation_topology.rb
  $ redstorm cluster examples/dsl/exclamation_topology2.rb
  $ redstorm cluster examples/dsl/word_count_topology.rb
  ```


#### Topologies with gems

For `examples/dsl/redis_word_count_topology.rb` the `redis` gem is required and you need a [Redis](http://redis.io/) server running on `localhost:6379`

1. create a `Gemfile`

  ``` ruby
  source "https://rubygems.org"

  group :word_count do
      gem "redis"
  end
  ```

2. install the topology gems

  ``` sh
  $ bundle install
  $ redstorm bundle word_count
  ```

3. genererate the `target/cluster-topology.jar` and include the `examples/` directory

  ``` sh
  $ redstorm jar examples
  ```

4. submit the cluster topology jar file to the cluster

  ``` sh
  $ redstorm cluster examples/dsl/redis_word_count_topology.rb
  ```

Using `redis-cli` push words into the `test` list and watch Storm pick them up

The [Storm wiki](https://github.com/nathanmarz/storm/wiki) has instructions on [setting up a production cluster](https://github.com/nathanmarz/storm/wiki/Setting-up-a-Storm-cluster). You can also [manually submit your topology](https://github.com/nathanmarz/storm/wiki/Running-topologies-on-a-production-cluster).

