class quickstack::pacemaker::qpid (
  $qpid_ip = '192.168.200.22',
) {
  pacemaker::resource::ip { "ip-$qpid_ip":
    ip_address => "$qpid_ip",
    group      => 'openstack_qpid',
  }
  ->
  pacemaker::resource::lsb { 'qpidd':
    group   => 'openstack_qpid',
    clone   => true,
  }

  class {'::quickstack::firewall::qpid':}

  Class['::qpid::server'] ->
  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::qpid']
}
