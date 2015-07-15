#!/usr/bin/env bash
#
# This bootstraps Puppet on Ubuntu 12.04 LTS.
# Based on: https://raw.githubusercontent.com/hashicorp/puppet-bootstrap/master/ubuntu.sh
#
set -e

# Install wget
sudo apt-get install -qy wget;

# Load up the release information
. /etc/lsb-release

REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT
#--------------------------------------------------------------------
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if which puppet > /dev/null 2>&1 -a apt-cache policy | grep --quiet apt.puppetlabs.com; then
  echo "Puppet is already installed."
  exit 0
fi

# Do the initial apt-get update
echo "Initial apt-get update..."
apt-get update >/dev/null

# Install wget if we have to (some older Ubuntu versions)
echo "Installing wget..."
apt-get install -y wget >/dev/null

# Install the PuppetLabs repo
echo "Configuring PuppetLabs repo..."
repo_deb_path=$(mktemp)
wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
dpkg -i "${repo_deb_path}" >/dev/null
apt-get update >/dev/null

# Install Puppet
echo "Installing Puppet..."
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install puppet >/dev/null

echo "Puppet installed!"

# Install RubyGems for the provider
echo "Installing RubyGems..."
if [ $DISTRIB_CODENAME != "trusty" ]; then
  apt-get install -y rubygems >/dev/null
fi
gem install --no-ri --no-rdoc rubygems-update
update_rubygems >/dev/null

mkdir -p /etc/puppet/modules;
if [ ! -d /etc/puppet/modules/file_concat ]; then
puppet module install ispavailability/file_concat
fi
if [ ! -d /etc/puppet/modules/apt ]; then
puppet module install puppetlabs-apt --version 1.8.0
fi
if [ ! -d /etc/puppet/modules/java ]; then
puppet module install puppetlabs-java
fi
if [ ! -d /etc/puppet/modules/elasticsearch ]; then
puppet module install elasticsearch-elasticsearch
fi
if [ ! -d /etc/puppet/modules/logstash ]; then
puppet module install elasticsearch-logstash
fi
if [ ! -f /etc/init.d/kibana ]; then
sudo cp /vagrant/kibana4_init /etc/init.d/kibana
sudo sed -i 's/\r//' /etc/init.d/kibana
sudo chmod +x /etc/init.d/kibana
sudo update-rc.d kibana defaults
fi
