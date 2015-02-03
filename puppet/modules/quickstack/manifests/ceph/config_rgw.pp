define quickstack::ceph::config_rgw (
  $index                = 0,
  $rgw_hostname_array   = [],
  $rgw_dns_name         = '',
) {

  if($index >= 0) {
    $rgw_local_hostname = $rgw_hostname_array[$index]

    concat::fragment{"tbag_footer":
      order   => 20-$index,
      target  => "/etc/ceph/ceph.conf"
      content => template('quickstack/ceph-conf-rgw.erb'),
    }

    #recurse
    $next = $index -1
    quickstack::ceph::config_rgw {"$name $next":
      index              => $next,
      rgw_hostname_array => $rgw_hostname_array,
      rgw_dns_name       => $rgw_dns_name,
    }
  }
}
