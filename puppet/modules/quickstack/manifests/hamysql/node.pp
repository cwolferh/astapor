class quickstack::hamysql::node (
  # these params aren't doing anything yet
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $mysql_bind_address         = '0.0.0.0',
  # Keystone
  $keystone_db_user       = 'keystone',
  $keystone_db_dbname     = 'keystone',
  # Glance
  $glance_db_user         = 'glance',
  $glance_db_dbname       = 'glance',
  # Nova
  $nova_db_user           = 'nova',
  $nova_db_dbname         = 'nova',
  # Cinder
  $cinder                 = true,
  $cinder_db_user         = 'cinder',
  $cinder_db_dbname       = 'cinder',
  # neutron
  $neutron                = true,
  $neutron_db_user        = 'neutron',
  $neutron_db_dbname      = 'neutron',

  # TODO's: mysql bind only on its vip, not 0.0.0.0
  # TODO: mysql account security
) inherits quickstack::params {

    #Package['mysql-server']     -> Class['quickstack::hamysql::node']
    #Package['MySQL-python']     -> Class['quickstack::hamysql::node']

    #@package {'MySQL-python':}
    #@package {'mysql-server':}

    yumrepo { 'clusterlabs' :
        baseurl => "http://clusterlabs.org/64z.repo",
        enabled => 1,
        priority => 1,
        gpgcheck => 0, # since the packages (eg pcs) don't appear to be signed
    }

    # these exec's could be useful if need to avoid using package {}
    # to avoid a puppet duplicate-declaration bug
    # (if we want to use more of puppet-mysql)
    #
    #exec { 'install-clu-and-mysql-deps-mysql-server':
    #   command => "/usr/bin/yum -y install mysql-server",
    #   timeout => 600,
    #   unless => "/bin/rpm -q --quiet --nodigest mysql-server"
    #}
    #exec { 'install-clu-and-mysql-deps-MySQL-python':
    #   command => "/usr/bin/yum -y install MySQL-python",
    #   timeout => 600,
    #   unless => "/bin/rpm -q --quiet --nodigest MySQL-python"
    #}
    #exec { 'install-clu-and-mysql-deps-ccs':
    #   command => "/usr/bin/yum -y install ccs",
    #   timeout => 600,
    #   unless => "/bin/rpm -q --quiet --nodigest ccs"
    #}
    #exec { 'install-clu-and-mysql-deps':
    #   command => "/bin/true",
    #   require => [Exec['install-clu-and-mysql-deps-mysql-server'],Exec['install-clu-and-mysql-deps-MySQL-python'],Exec['install-clu-and-mysql-deps-ccs']]
    #}
    #class { 'install-clu-and-mysql-deps' } {
    #    requires => [[Package['mysql-server'],Package['MySQL-python']
    #}

    #package { 'hamy-MySQL-python':
    #   alias => 'hamy-MySQL-python',
    #   name => 'MySQL-python',
    #   ensure => installed,
    #}
    #class { 'mysql::server':
    #  manage_service => false,
    #  enabled => false,
    #  config_hash => {
    #    'root_password' => 'UNSET',
    #    'bind_address'  => $mysql_bind_address,
    #  },
    #}
    package { 'mysql-server':
       ensure => installed,
    }
    package { 'MySQL-python':
       ensure => installed,
    }
    package { 'ccs' :
       ensure => installed,
    }
    #package { 'MySQL-python':
    #   alias => 'hamy-MySQL-python',
    #   name => 'MySQL-python',
    #   ensure => installed,
    #}

    class {'quickstack::hamysql::mysql::config':
       bind_address =>  $mysql_bind_address,
       #require => Exec['install-clu-and-mysql-deps']
       require => [Package['mysql-server'],Package['MySQL-python']]
       #require => [Package<| 'mysql-server' |>,Package<| 'MySQL-python' |>]
       #include mysql-server
       #reailze Package['mysql-server']
    }

    class {'pacemaker::corosync':
        cluster_name => "hamysql",
        cluster_members => "192.168.200.11 192.168.200.12 192.168.200.13 ",
        require => [Yumrepo['clusterlabs'],Package['mysql-server'],Package['MySQL-python'],Package['ccs'],Class['quickstack::hamysql::mysql::config']],
        #require => [Yumrepo['clusterlabs'],Exec['install-clu-and-mysql-deps'],Class['quickstack::hamysql::mysql::config']],
    }

    class {"pacemaker::resource::ip":
      ip_address => "192.168.200.50",
      group => "mygroup",
      #cidr_netmask => "24",
      #nic => "eth3",
    }
    class {"pacemaker::stonith":
        disable => true,
    }
    class {"pacemaker::resource::filesystem":
       device => "192.168.200.200:/mnt/mysql",
       directory => "/var/lib/mysql",
       fstype => "nfs",
       group => "mygroup",
       require => Class['pacemaker::resource::ip'],
    }
    class {"pacemaker::resource::mysql":
      name => "ostk-mysql",
      group => "mygroup",
      require => Class['pacemaker::resource::filesystem'],
    }

    # not necessary, will already be in correct order
    #exec {"set-hamysql-ordering":
    #  command => "/usr/sbin/pcs constraint order set ip-192.168.200.50 fs-varlibmysql ostk-mysql",
    #  require => Class['pacemaker::resource::mysql'],
    #}

   exec {"wait-for-mysql-to-start":
       timeout => 3600,
       tries => 360,
       try_sleep => 10,
       command => "/usr/sbin/pcs status  | grep -q 'mysql-ostk-mysql.*Started' > /dev/null 2>&1",
       require => Class['pacemaker::resource::mysql'],
   }

    class {'quickstack::hamysql::mysql::rootpw':
       require => Exec['if-we-are-running-mysql'],
       root_password => $mysql_root_password,
    }

   file {"are-we-running-mysql-script":
    name => "/tmp/are-we-running-mysql.bash",
      ensure => present,
      owner => root,
      group => root,
      mode  => 777,
      content => "#!/bin/bash\n a=`/usr/sbin/pcs status | grep mysql-ostk-mysql | perl -p -e 's/^.*Started (\S*).*$/\$1/'`; b=`/usr/sbin/crm_node -n`; echo \$a; echo \$b; \ntest \$a = \$b;",
      require => Exec['wait-for-mysql-to-start'],
   }
   exec {"if-we-are-running-mysql":
      command => "/bin/touch /tmp/WE-ARE-ACTIVE",
      require => Exec['wait-for-mysql-to-start'],
      #require => File['are-we-running-mysql-script'],
      onlyif => "/tmp/are-we-running-mysql.bash",
   }

  #mysql::db { $dbname:
  #  user         => $user,
  #  password     => $password,
  #  host         => $host,
  #  charset      => $charset,
  #  require      => Class['mysql::config'],
  #}

  # TODO use IP other than 127.0.0.1 if $mysql_bind_address is not 0.0.0.0
  database { $keystone_db_dbname:
    ensure => 'present',
    provider => 'mysql',
    require => Class['quickstack::hamysql::mysql::rootpw'],
  }
  database_user { "$keystone_db_user@127.0.0.1":
    ensure => 'present',
    password_hash => mysql_password($keystone_db_password),
    provider      => 'mysql',
    require       => Database[$keystone_db_dbname],
  }
  database { $glance_db_dbname:
    ensure => 'present',
    provider => 'mysql',
    require => Class['quickstack::hamysql::mysql::rootpw'],
  }
  database_user { "$glance_db_user@127.0.0.1":
    ensure => 'present',
    password_hash => mysql_password($glance_db_password),
    provider      => 'mysql',
    require       => Database[$glance_db_dbname],
  }

  database { $nova_db_dbname:
    ensure => 'present',
    provider => 'mysql',
    require => Class['quickstack::hamysql::mysql::rootpw'],
  }
  database_user { "$nova_db_user@127.0.0.1":
    ensure => 'present',
    password_hash => mysql_password($nova_db_password),
    provider      => 'mysql',
    require       => Database[$nova_db_dbname],
  }

  database { $cinder_db_dbname:
    ensure => 'present',
    provider => 'mysql',
    require => Class['quickstack::hamysql::mysql::rootpw'],
  }
  database_user { "$cinder_db_user@127.0.0.1":
    ensure => 'present',
    password_hash => mysql_password($cinder_db_password),
    provider      => 'mysql',
    require       => Database[$cinder_db_dbname],
  }

  # would prefer to use below than use "database" and "database_user"
  # but that opens a can of bloody puppet worms
  # maybe TODO: try using exec's instead of Package's to avoid
  #      Could not retrieve catalog from remote server: Error 400 on SERVER: Puppet::Parser::AST::Resource failed with error ArgumentError: Cannot alias Package[python-mysqldb] to ["MySQL-python"] at /etc/puppet/environments/production/modules/mysql/manifests/python.pp:24; resource ["Package", "MySQL-python"] already declared at /etc/puppet/environments/production/modules/quickstack/manifests/hamysql/node.pp:89 at /etc/puppet/environments/production/modules/mysql/manifests/python.pp:24 on node s6ha1c1.example.com
  #class { 'keystone::db::mysql':
  #  user          => $keystone_db_user,
  #  password      => $keystone_db_password,
  #  dbname        => $keystone_db_dbname,
  #  allowed_hosts => $allowed_hosts,
  #  require => Exec['wait-for-mysql-to-start'],
  #}
  #

  # even better, would prefer to use below
  # but that opens a couple of cans of bloody puppet worms
#  class {'openstack::db::mysql':
#      mysql_root_password  => $mysql_root_password,
#      keystone_db_password => $keystone_db_password,
#      glance_db_password   => $glance_db_password,
#      nova_db_password     => $nova_db_password,
#      cinder_db_password   => $cinder_db_password,
#      neutron_db_password  => '',
#
#      # MySQL
#      mysql_bind_address     => '0.0.0.0',
#      mysql_account_security => true,
#
#      # Cinder
#      cinder                 => false,
#
#      # neutron
#      neutron                => false,
#
#      allowed_hosts          => '%',
#      enabled                => true,
#      require                => Exec['if-we-are-running-mysql']
#  }
}
