class quickstack::hamysql::node (
  # these params aren't doing anything yet
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $keystone_db_user            = 'keystone',
  $keystone_db_dbname          = 'keystone',
  $mysql_bind_address         = '0.0.0.0'
) inherits quickstack::params {

    yumrepo { 'clusterlabs' :
        baseurl => "http://clusterlabs.org/64z.repo",
        enabled => 1,
        priority => 1,
        gpgcheck => 0, # since the packages (eg pcs) don't appear to be signed
    }

    package { 'MySQL-python' :
       ensure => installed,
    }
    #class { 'mysql::server':
    #  manage_service => false,
    #  enabled => false,
    #  config_hash => {
    #    'root_password' => 'UNSET',
    #    'bind_address'  => $mysql_bind_address,
    #  },
    #}
    package { 'mysql-server' :
       ensure => installed,
    }
    package { 'ccs' :
       ensure => installed,
    }

    class {'pacemaker::corosync':
        cluster_name => "hamysql",
        cluster_members => "192.168.200.11 192.168.200.12 192.168.200.13 ",
        require => [Yumrepo['clusterlabs'],Package['mysql-server'],Package['MySQL-python'],Package['ccs']],
        #require => [Yumrepo['clusterlabs'],Class['mysql::server'], Package['ccs']],
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
    }
    class {"pacemaker::resource::mysql":
      name => "ostk-mysql",
      group => "mygroup",
      require => [Class['pacemaker::resource::filesystem'],Class['pacemaker::resource::ip']],
    }

    # not necessary, will already be in correct order
    #exec {"set-hamysql-ordering":
    #  command => "/usr/sbin/pcs constraint order set ip-192.168.200.50 fs-varlibmysql ostk-mysql",
    #  require => Class['pacemaker::resource::mysql'],
    #}

 ##   exec {"wait-for-quorum":  TODO

   #exec {"is-this-the-active-node":
   #   command => "/usr/bin/test `pcs status | grep mysql-ostk-mysql | perl -p -e 's/^.*Started (.*)/$1/'` = `crm_node -n`",
   #   require => Class['pacemaker::resource::mysql'],
   #}

#    class { 'keystone::db::mysql':
#      user          => $keystone_db_user,
#      password      => $keystone_db_password,
#      dbname        => $keystone_db_dbname,
#      allowed_hosts => $allowed_hosts,
#      require       => Exec['is-this-the-active-node'],
#    }
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
#      require                => Exec['is-this-the-active-node']
#  }

}
