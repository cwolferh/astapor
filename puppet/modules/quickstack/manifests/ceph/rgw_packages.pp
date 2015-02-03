class quickstack::ceph::rgw_packages {

  # note that mod_proxy_fcgi is included in httpd in el7
  $ceph_rgw_packages = ['ceph-radosgw']

  package { $ceph_rgw_packages: ensure => "installed" }
}
