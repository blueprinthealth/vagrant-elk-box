file { '/vagrant/elasticsearch':
  ensure => 'directory',
  group  => 'vagrant',
  owner  => 'vagrant',
}

# Java is required
package { 'java':
  ensure => present,
  name => 'java-1.7.0-openjdk.x86_64',
}
#package { 'java-1.7.0-openjdk': ensure => latest }

$elasticsearch_root_backupdir = '/var/backups'
file { $elasticsearch_root_backupdir:
  ensure  => 'directory',
  owner   => 'root',
  group   => 'root',
  mode    => '0744',
}

# Elasticsearch
class { 'elasticsearch':
  ensure       => 'present',
  manage_repo  => true,
  repo_version => '1.6',
  java_install => false,

  require      => [
    Package['java'],
    File[$elasticsearch_root_backupdir]
  ]
}

$elasticsearch_port = 9200
$elasticsearch_instance_name = 'es-01'
elasticsearch::instance { $elasticsearch_instance_name:
  config => { 
  'cluster.name'             => 'vagrant_elasticsearch',
  'index.number_of_replicas' => '0',
  'index.number_of_shards'   => '1',
  'network.host'             => '0.0.0.0',
  'http.port'                => $elasticsearch_port,
  'path.repo'                => [$elasticsearch_root_backupdir],
  },        # Configuration hash
  init_defaults => { }, # Init defaults hash

  before => Service['kibana']
}

elasticsearch::plugin{'royrusso/elasticsearch-HQ':
  module_dir => 'HQ',
  instances  => $elasticsearch_instance_name
}

# Logstash
class { 'logstash':
  # autoupgrade  => true,
  ensure       => 'present',
  manage_repo  => true,
  repo_version => '1.5',
  java_install => false,

  require      => [
    Package['java'],
    Elasticsearch::Instance[$elasticsearch_instance_name],
  ],
}

logstash::configfile { 'metrics':
 source => '/vagrant/confs/logstash/logstash.conf',
}

# Kibana
class { 'kibana':
  version => '4.1.1',
  port    => '5601',
  es_url  => "http://localhost:${elasticsearch_port}",
  legacy_service_mode => true,

  require => [
    Package['java'],
    Elasticsearch::Instance[$elasticsearch_instance_name],
  ]
}
