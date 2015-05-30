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
    resource_name => "redis",
    resource_params => "wait_last_known_master=true --master meta notify=true ordered=true interleave=true",
  } ->
  quickstack::pacemaker::vips { $redis_group:
    public_vip   => $_redis_vip,
    private_vip  => $_redis_vip,
    admin_vip    => $_redis_vip,
  } ->

  quickstack::pacemaker::constraint::typical { 'redis-master-then-vip-redis':
    first_resource  => 'redis-master',
    second_resource => "ip-redis-pub-${_redis_vip}",
    first_action    => 'promote',
  }
}
