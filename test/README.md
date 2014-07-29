# Integration Tests

These are integration tests to automate the testing of topology submission in a local and remote cluster. More documentation on usage to come.

##Prerequisites
  * Storm cluster available 
    * Run the vagrant machine - https://github.com/colinsurprenant/redstorm/blob/master/vagrant/README.md
    * Setup a storm cluster - https://storm.incubator.apache.org/documentation/Setting-up-a-Storm-cluster.html
  * Redis Server listening on localhost:6379
    * Run the vagrant machine - https://github.com/colinsurprenant/redstorm/blob/master/vagrant/README.md
    * Install redis locally - http://redis.io/download
  * Storm client installed locally - http://storm.incubator.apache.org/documentation/Setting-up-development-environment.html
  * ~/.storm/storm.yaml pointing at your storm cluster - eg. ``nimbus.host: "localhost"``

##Running tests

  * ``$ test/integration/run_all.sh`` - Uses locally bundled redstorm
  * ``$ REDSTORM_COMMAND=/usr/bin/redstorm test/integration/run_all.sh`` - Set REDSTORM_COMMAND to use a specific redstorm binary