# == Class: quickstack::db::nosql
#
# Install a nosql server (MongoDB)
#
# === Parameters:
#
# [*bind_host*]
#   (optional) IP address on which mongod instance should listen
#   Defaults to '127.0.0.1'
#
# [*nojournal*]
#   (optional) Disable mongodb internal cache. This is not recommended for
#   production but results in a much faster boot process.
#   http://docs.mongodb.org/manual/reference/configuration-options/#nojournal
#   Defaults to false
#
# [*port*]
#   (optional) Port on which mongod instance should listen
#   Defaults to '27017'
#
# [*service_enable*]
#   (optional) Whether to enable the system unit for mongo server
#   Defaults to true
#
# [*service_ensure*]
#   (optional) Whether to start or stop the mongo server. Set to undef
#   to tell puppet not to manage the service status.
#   Defaults to 'running'


class quickstack::db::nosql(
  $bind_host       = '127.0.0.1',
  $nojournal       = false,
  $port            = '27017',
  $service_enable  = true,
  $service_ensure  = 'running',
) {

  anchor {'mongodb setup start': }
  ->
  class { '::mongodb::globals':
    service_enable => $service_enable,
    service_ensure => $service_ensure,
  }
  ->
  class {'mongodb::client':}
  ->
  class { '::mongodb':
    bind_ip   => [$bind_host,'127.0.0.1'],
    nojournal => $nojournal,
    port      => $port,
    replset   => 'ceilometer',
  }
  ->
  exec {'check_mongodb' :
    command   => "/usr/bin/mongo ${bind_host}:27017",
    logoutput => false,
    tries     => 60,
    try_sleep => 5,
    require   => Service['mongodb'],
  }

  anchor {'mongodb setup done' :
    require => Exec['check_mongodb'],
  }
}
