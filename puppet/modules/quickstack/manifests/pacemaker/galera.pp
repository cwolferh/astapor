class quickstack::pacemaker::galera (
  $mysql_root_password     = '',
  $galera_monitor_username = 'monitor_user',
  $galera_monitor_password = 'monitor_pass',
  $wsrep_cluster_name      = 'galera_cluster',
  $wsrep_cluster_members   = [],
  $wsrep_sst_method        = 'rsync',
  $wsrep_sst_username      = 'sst_user',
  $wsrep_sst_password      = 'sst_pass',
  $wsrep_ssl               = false,
  $wsrep_ssl_key           = '/etc/pki/galera/galera.key',
  $wsrep_ssl_cert          = '/etc/pki/galera/galera.crt',
) {

  include quickstack::pacemaker::common

  if (str2bool_i(map_params('include_mysql'))) {
    $galera_vip = map_params("db_vip")
    if ($::pcs_setup_galera ==  undef or
        !str2bool_i("$::pcs_setup_galera")) {
      $_enabled = true
      $_ensure = 'running'
    } else {
      $_enabled = false
      $_ensure = undef
    }

    Exec['all-memcached-nodes-are-up'] -> Service['galera']
    Class['::quickstack::pacemaker::rsync::galera'] -> Service['galera']

    if (has_interface_with("ipaddress", map_params("cluster_control_ip")) and str2bool_i($::galera_bootstrap_ok)) {
      $galera_bootstrap = true
      $galera_test      = "/bin/true"
    } else {
      $galera_bootstrap = false
      $galera_test     = "/tmp/ha-all-in-one-util.bash property_exists galera"
    }

    quickstack::pacemaker::manual_service { "mariadb":
      stop  => $_enabled,
    }

    class {"::quickstack::load_balancer::galera":
      frontend_pub_host    => map_params("db_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }

    Class['::quickstack::pacemaker::common']
    ->
    quickstack::pacemaker::vips { "galera":
      public_vip  => map_params("db_vip"),
      private_vip => map_params("db_vip"),
      admin_vip   => map_params("db_vip"),
    } ->
    class {'::quickstack::firewall::galera':} ->
    exec {"galera-bootstrap-OR-galera-property-exists":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => $galera_test,
      unless    => $galera_test,
    } ->
    class { "::quickstack::pacemaker::rsync::galera":
      cluster_control_ip => map_params("cluster_control_ip"),
    } ->
    class { '::quickstack::galera::server':
      mysql_bind_address      => map_params("local_bind_addr"),
      mysql_root_password     => $mysql_root_password,
      galera_bootstrap        => $galera_bootstrap,
      galera_monitor_username => $galera_monitor_username,
      galera_monitor_password => $galera_monitor_password,
      service_enable          => $_enabled,
      service_ensure          => $_ensure,
      wsrep_cluster_name      => $wsrep_cluster_name,
      wsrep_cluster_members   => $wsrep_cluster_members,
      wsrep_sst_method        => $wsrep_sst_method,
      wsrep_sst_username      => $wsrep_sst_username,
      wsrep_sst_password      => $wsrep_sst_password,
      wsrep_ssl               => $wsrep_ssl,
      wsrep_ssl_key           => $wsrep_ssl_key,
      wsrep_ssl_cert          => $wsrep_ssl_cert,
    } ->
    class {"::mysql::server::account_security": } ->
    class {"::quickstack::galera::db":
      keystone_db_password => map_params("keystone_db_password"),
      glance_db_password   => map_params("glance_db_password"),
      nova_db_password     => map_params("nova_db_password"),
      cinder_db_password   => map_params("cinder_db_password"),
      heat_db_password     => map_params("heat_db_password"),
      neutron_db_password  => map_params("neutron_db_password"),
      require              => File['/root/.my.cnf'],
    } ->
    exec {"pcs-galera-server-setup":
      command => "/usr/sbin/pcs property set galera=running --force",
    } ->
    exec {"clustercheck-sync":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/usr/bin/clustercheck >/dev/null",
    } ->
    exec {"pcs-galera-server-set-up-on-this-node":
      command => "/tmp/ha-all-in-one-util.bash update_my_node_property galera"
    } ->
    exec {"all-galera-nodes-are-up":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/tmp/ha-all-in-one-util.bash all_members_include galera",
    }

    if str2bool_i($::galera_bootstrap_ok) {
      Exec['all-galera-nodes-are-up'] ->
      Quickstack::Pacemaker::Manual_Service['mariadb'] ->
      exec {"pcs-galera-server-stopped-after-bootstrap":
        command => "/tmp/ha-all-in-one-util.bash update_my_node_property galera-post-bootstrap"
      } ->
      exec {"all-galera-finished-post-bootstrap":
        timeout   => 3600,
        tries     => 360,
        try_sleep => 10,
        command   => "/tmp/ha-all-in-one-util.bash all_members_include galera-post-bootstrap",
      } ->
      Quickstack::Pacemaker::Resource::Service['mysqld']
    } else {
      Exec['all-galera-nodes-are-up'] ->
      Quickstack::Pacemaker::Manual_Service['mariadb'] ->
      Quickstack::Pacemaker::Resource::Service['mysqld']
    }

    quickstack::pacemaker::resource::service {'mysqld':
      group          => "$pcmk_galera_group",
      options        => 'start timeout=300s meta ordered=true',
      clone          => true,
    } ->
    # one last clustercheck to make sure service is up
    exec {"galera-online":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/usr/bin/clustercheck >/dev/null",
    }
  }
}
