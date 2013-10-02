class quickstack::hamysql::node (
  # these params aren't doing anything yet
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
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
    package { 'mysql-server' :
       ensure => installed,
    }
    package { 'ccs' :
       ensure => installed,
    }

#    class {'openstack::db::mysql':
#        mysql_root_password  => $mysql_root_password,
#        keystone_db_password => $keystone_db_password,
#        glance_db_password   => $glance_db_password,
#        nova_db_password     => $nova_db_password,
#        cinder_db_password   => $cinder_db_password,
#        neutron_db_password  => '',
#
#        # MySQL
#        mysql_bind_address     => '0.0.0.0',
#        mysql_account_security => true,
#
#        # Cinder
#        cinder                 => false,
#
#        # neutron
#        neutron                => false,
#
#        allowed_hosts          => '%',
#        enabled                => true,
#    }


    class {'pacemaker::corosync':
        cluster_name => "hamysql",
        cluster_members => "192.168.200.11 192.168.200.12 192.168.200.13 ",
        require => [Yumrepo['clusterlabs'],Package['mysql-server'],Package['MySQL-python'],Package['ccs']],
    }

    class {"pacemaker::resource::ip":
      ip_address => "192.168.200.50",
      group => "mygroup",
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
      require => Class['pacemaker::resource::filesystem'],
    }
    #class {"pacemaker::resource::lsb":
    #   name => "mysqld",
    #   group => "my_group",
    #}
}
