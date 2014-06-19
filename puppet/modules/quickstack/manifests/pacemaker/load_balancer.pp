class quickstack::pacemaker::load_balancer {

  include quickstack::pacemaker::common

  $loadbalancer_group = map_params("loadbalancer_group")
  $loadbalancer_vip   = map_params("loadbalancer_vip")

  quickstack::pacemaker::vips { "$loadbalancer_group":
    public_vip  => $loadbalancer_vip,
    private_vip => $loadbalancer_vip,
    admin_vip   => $loadbalancer_vip,
  }
  if (map_params('include_keystone')) {
    class {"::quickstack::load_balancer::keystone":
      frontend_pub_host    => map_params("keystone_public_vip"),
      frontend_priv_host   => map_params("keystone_private_vip"),
      frontend_admin_host  => map_params("keystone_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
  }
  if (map_params('include_heat')) {
    class {"::quickstack::load_balancer::heat":
      frontend_heat_pub_host              => map_params("heat_public_vip"),
      frontend_heat_priv_host             => map_params("heat_private_vip"),
      frontend_heat_admin_host            => map_params("heat_admin_vip"),
      frontend_heat_cfn_pub_host          => map_params("heat_cfn_public_vip"),
      frontend_heat_cfn_priv_host         => map_params("heat_cfn_private_vip"),
      frontend_heat_cfn_admin_host        => map_params("heat_cfn_admin_vip"),
      backend_server_names                => map_params("lb_backend_server_names"),
      backend_server_addrs                => map_params("lb_backend_server_addrs"),
      heat_cfn_enabled                    => $heat_cfn_enabled,
      heat_cloudwatch_enabled             => $heat_cloudwatch_enabled,
    }
  }
  if (map_params('include_swift')) {
    class {"::quickstack::load_balancer::swift":
      frontend_pub_host    => map_params("swift_public_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
  }
  # to include qpid here, need to move $backend_port and $haproxy_timeout
  # as shared params.pp
  #if (map_params('include_qpid')) {
  #  class {'::quickstack::load_balancer::qpid':
  #    frontend_host        => map_params("qpid_vip"),
  #    backend_server_names => map_params("lb_backend_server_names"),
  #    backend_server_addrs => map_params("lb_backend_server_addrs"),
  #    port                 => map_params("qpid_port"),
  #    backend_port         => $backend_port,
  #    timeout              => $haproxy_timeout,
  #  }
  #}
  if (map_params('include_cinder')) {
    class {"::quickstack::load_balancer::cinder":
      frontend_pub_host    => map_params("cinder_public_vip"),
      frontend_priv_host   => map_params("cinder_private_vip"),
      frontend_admin_host  => map_params("cinder_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
  }
  if (map_params('include_neutron')) {
    class {"::quickstack::load_balancer::neutron":
      frontend_pub_host    => map_params("neutron_public_vip"),
      frontend_priv_host    => map_params("neutron_private_vip"),
      frontend_admin_host    => map_params("neutron_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
  }
  if (map_params('include_glance')) {
    class {"::quickstack::load_balancer::glance":
      frontend_pub_host    => map_params("glance_public_vip"),
      frontend_priv_host   => map_params("glance_private_vip"),
      frontend_admin_host  => map_params("glance_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
  }
  if (map_params('include_nova')) {
    class {"::quickstack::load_balancer::nova":
      frontend_pub_host    => map_params("nova_public_vip"),
      frontend_priv_host   => map_params("nova_private_vip"),
      frontend_admin_host  => map_params("nova_admin_vip"),
      backend_server_names => map_params("lb_backend_server_names"),
      backend_server_addrs => map_params("lb_backend_server_addrs"),
    }
  }

  Service['haproxy'] ->
  exec {"pcs-haproxy-server-set-up-on-this-node":
    command => "/tmp/ha-all-in-one-util.bash update_my_node_property haproxy"
  } ->
  exec {"all-haproxy-nodes-are-up":
    timeout   => 3600,
    tries     => 360,
    try_sleep => 10,
    command   => "/tmp/ha-all-in-one-util.bash all_members_include haproxy",

  } ->
  quickstack::pacemaker::resource::service {'haproxy':
    clone => true,
  }
}
