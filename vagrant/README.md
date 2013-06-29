# Vagrant/Chef single node Storm cluster VM

Installs Java, Storm and Redis.

Redirects these ports on local Virtualbox VM:

- 8080 for Storm UI
- 6627 for Storm Nimbus Thrift for topology submissions
- 6379 for Redis

# Install

- install vagrant
- `$ vagrant plugin install vagrant-omnibus` see https://github.com/schisamo/vagrant-omnibus
- `$ vagrant plugin install vagrant-aws` see https://github.com/mitchellh/vagrant-aws
- MRI Ruby required, JRuby cannot install the gems
- `$ bundle install`
- `$ bundle exec librarian-chef install`
- edit databags/users/storm.json
- edit storm options in Vagranfile

# Local Virtualbox usage

- `$ vagrant up dev`
- `$ ssh storm@localhost -p 2222`

# EC2 usage

- edit EC2 options in Vagrantfile
- `$ vagrant up prod --provider=aws`
