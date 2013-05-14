#!/bin/bash

TOPOLOGIES=test/topology/*.rb
COMMANDS=("redstorm" "bundle exec redstorm" "bin/redstorm" )
REDSTORM=""

export PATH="$PATH:./storm/bin"

# figure correct command
for c in "${COMMANDS[@]}"; do
  $c version &> /dev/null
  if [ $? -eq 0 ]; then
    REDSTORM=$c
    break
  fi
done
if [ "$REDSTORM" == "" ]; then
  echo "redstorm command not found"
  exit 1
fi

if [[ $@ != "noinstall" ]]; then
  # install target
  rm -rf target
  bundle install
  $REDSTORM install 
  $REDSTORM bundle topology
  $REDSTORM jar test
fi

echo "runnig integration tests..."

# run local mode tests
for t in $TOPOLOGIES; do
  echo -n "local $t " 
  ruby test/integration/run_local.rb $t
done


# run cluster mode tests
for t in $TOPOLOGIES; do
  echo -n "cluster $t "
  ruby test/integration/run_remote.rb $t
done