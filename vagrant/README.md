# Vagrant/Chef single node Storm cluster VM

Installs Java 1.7.0, Storm 0.8.2 and Redis.

Redirects these ports on VM:

- 8080 for Storm UI
- 6627 for Storm Nimbus Thrift for topology submissions
- 6379 for Redis

# Usage

- install vagrant
- vagrant plugin install [vagrant-omnibus](https://github.com/schisamo/vagrant-omnibus)
- MRI Ruby required, JRuby cannot install the gems
- bundle install
- bundle exec librarian-chef install
- edit databags/users/storm.json
- edit storm options in Vagranfile
- vagrant up dev
- ssh storm@localhost -p 2222
