class quickstack::pacemaker::redis(
  $bind_host             = '127.0.0.1',
  $port                  = '6379',
  $slaveof               = undef,
) {

  $redis_group = map_params("redis_group")

  class {'::quickstack::firewall::redis':
    ports => [$port],
  }

  class {'::quickstack::db::redis':
    bind_host => $bind_host,
    port      => $port,
    slaveof   => $slaveof,
  }

  $_redis_vip = map_params('redis_vip')

  quickstack::pacemaker::resource::generic {'redis':
    resource_name => '',
    resource_type => 'redis',
    resource_params => "wait_last_known_master=true --master meta notify=true ordered=true interleave=true",
  } ->
  quickstack::pacemaker::vips { $redis_group:
    public_vip   => $_redis_vip,
    private_vip  => $_redis_vip,
    admin_vip    => $_redis_vip,
  } ->
  quickstack::pacemaker::constraint::base { 'redis-master-then-vip-redis':
    constraint_type => "order",
    first_resource  => 'redis-master',
    second_resource => "ip-redis-pub-${_redis_vip}",
    first_action    => 'promote',
    second_action   => "start",
  }
  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    Quickstack::Pacemaker::Constraint::Base['redis-master-then-vip-redis'] ->
    exec{ 'redis-master-and-vip-colo':
      command => "pcs constraint colocation add ip-redis-pub-${_redis_vip} with master redis-master",
      unless => "bash -c 'pcs constraint show | grep -qs \"ip-redis-pub-${_redis_vip} with redis-master\"'",
      path => ['/usr/sbin', '/usr/bin'],
    }
  }
}
