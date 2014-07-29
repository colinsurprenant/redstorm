#!/bin/bash

TOPOLOGIES=test/topology/*.rb
COMMANDS=("bundle exec redstorm" "bin/redstorm" )

if test -z "${REDSTORM_COMMAND}"
then
  # figure correct command
  for c in "${COMMANDS[@]}"; do
    $c version &> /dev/null
    if [ $? -eq 0 ]; then
      REDSTORM_COMMAND=$c
      break
    fi
  done
fi
echo "Using '${REDSTORM_COMMAND}' as the redstorm command"

$REDSTORM_COMMAND version &> /dev/null
if [ $? -ne 0 ]; then
  echo "redstorm command not found"
  exit 1
fi

if [[ $@ != "noinstall" ]]; then
  # install target
  rm -rf target
  bundle install
  $REDSTORM_COMMAND install
  $REDSTORM_COMMAND bundle topology
  $REDSTORM_COMMAND jar test
fi

echo "running integration tests..."

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