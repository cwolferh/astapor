class quickstack::hamysql::node (
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,

  # these two variables are distinct because you may want to bind on
  # '0.0.0.0' rather than just the floating ip
  $mysql_bind_address          = $quickstack::params::mysql_host,
  $mysql_virtual_ip            = $quickstack::params::mysql_host,
  $mysql_virt_ip_nic           = $quickstack::params::mysql_virt_ip_nic,
  $mysql_virt_ip_cidr_mask     = $quickstack::params::mysql_virt_ip_cidr_mask,
  # e.g. "192.168.200.200:/mnt/mysql"
  $mysql_shared_storage_device = $quickstack::params::mysql_shared_storage_device,  
  # e.g. "nfs"
  $mysql_shared_storage_type   = $quickstack::params::mysql_shared_storage_type,
  $mysql_resource_group_name   = $quickstack::params::mysql_resource_group_name,
  $mysql_clu_member_addrs      = $quickstack::params::mysql_clu_member_addrs,
  
  # The usual OpenStack db users/names
  $keystone_db_user       = 'keystone',
  $keystone_db_dbname     = 'keystone',
  $glance_db_user         = 'glance',
  $glance_db_dbname       = 'glance',
  $nova_db_user           = 'nova',
  $nova_db_dbname         = 'nova',
  #  $cinder                 = true,
  $cinder_db_user         = 'cinder',
  $cinder_db_dbname       = 'cinder',
  #  $neutron                = true,
  $neutron_db_user        = 'neutron',
  $neutron_db_dbname      = 'neutron',

  # TODO's:
  #  -mysql bind only on its vip, not 0.0.0.0
  #  -mysql account security
  #  -parameterize cluster member IP's
  #  -parameterize vip
) inherits quickstack::params {

    yumrepo { 'clusterlabs' :
        baseurl => "http://clusterlabs.org/64z.repo",
        enabled => 1,
        priority => 1,
        gpgcheck => 0, # since the packages (eg pcs) don't appear to be signed
    }

    package { 'mysql-server':
       ensure => installed,
    }
    package { 'MySQL-python':
       ensure => installed,
    }
    package { 'ccs' :
       ensure => installed,
    }

    class {'quickstack::hamysql::mysql::config':
       bind_address =>  $mysql_bind_address,
       require => [Package['mysql-server'],Package['MySQL-python']]
    }

    class {'pacemaker::corosync':
        cluster_name => "hamysql",
        cluster_members => "192.168.200.11 192.168.200.12 192.168.200.13 ",
        require => [Yumrepo['clusterlabs'],Package['mysql-server'],Package['MySQL-python'],Package['ccs'],Class['quickstack::hamysql::mysql::config']],
    }

    class {"pacemaker::resource::ip":
      #ip_address => "192.168.200.50",
      ip_address => $mysql_virtual_ip,
      group => $mysql_resource_group_name,
      cidr_netmask => $mysql_virt_ip_cidr_mask,
      nic => $mysql_virt_ip_nic,
    }
    class {"pacemaker::stonith":
        disable => true,
    }
    class {"pacemaker::resource::filesystem":
       #device => "192.168.200.200:/mnt/mysql",
       device => "$mysql_shared_storage_device",
       directory => "/var/lib/mysql",
       #fstype => "nfs",
       fstype => $mysql_shared_storage_type,
       group => $mysql_resource_group_name,
       require => Class['pacemaker::resource::ip'],
    }
    class {"pacemaker::resource::mysql":
      name => "ostk-mysql",
      group => $mysql_resource_group_name,
      require => Class['pacemaker::resource::filesystem'],
    }

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
      onlyif => "/tmp/are-we-running-mysql.bash",
   }

   class {'quickstack::hamysql::mysql::setup':
      keystone_db_password => $keystone_db_password,
      glance_db_password   => $glance_db_password,
      nova_db_password     => $nova_db_password,
      cinder_db_password   => $cinder_db_password,
      require              => Class['quickstack::hamysql::mysql::rootpw'],
   }

}
