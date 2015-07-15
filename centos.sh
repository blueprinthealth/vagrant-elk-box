#!/bin/bash

set -e

echo "---fixing vagrant file perms---"
chmod 0440 /etc/sudoers.d/vagrant

echo "---upgrading ruby to 1.9.3---"
yum install -y centos-release-SCL
yum install -y ruby193 ruby193-ruby-devel gcc

echo "---installing puppet---"
if ! rpm -qa | grep -i 'puppetlabs-release' > /dev/null; then
    rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
fi
yum install -y puppet git

echo "---installing librarian-puppet---"
(. /opt/rh/ruby193/enable; gem install librarian-puppet -v 2.1.0)

echo "---installing puppet modules---"
LIBRARIAN_PUPPET_EXEC="/opt/rh/ruby193/root/usr/local/share/gems/gems/librarian-puppet-2.1.0/bin/librarian-puppet"
(. /opt/rh/ruby193/enable; cd /vagrant; $LIBRARIAN_PUPPET_EXEC install --path=/vagrant/modules)
