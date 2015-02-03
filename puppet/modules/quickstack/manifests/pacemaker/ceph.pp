# Write ceph config files and configure a ceph object store gateway
#
# === Parameters
#
# [*ceph_manage_ceph_conf*]
#   (optional) Whether or not to write /etc/ceph/ceph.conf.
#
# [*ceph_manage_rgw*]
#    (optional) Whether or not to setup a vip, haproxy, apache for a
#    ceph radoswgw gateway and install packages required for radosgw.
#


class quickstack::pacemaker::ceph(
  $ceph_manage_ceph_conf        = false,
  $ceph_manage_rgw              = false,
  $ceph_cluster_network         = '',
  $ceph_public_network          = '',
  $ceph_fsid                    = '',
  $ceph_images_key              = '',
  $ceph_volumes_key             = '',
  $ceph_rgw_key                 = '',
  $ceph_mon_host                = [],
  $ceph_mon_initial_members     = [],
  $ceph_conf_include_osd_global = true,
  $ceph_osd_pool_size           = '',
  $ceph_osd_journal_size        = '',
  $ceph_osd_mkfs_options_xfs    = '-f -i size=2048 -n size=64k',
  $ceph_osd_mount_options_xfs   = '-o inode64,noatime,logbsize=256k',
  $ceph_conf_include_rgw        = true,
  $ceph_rgw_keyring_filename    = '/etc/ceph/ceph.client.radosgw.keyring',
  $ceph_rgw_config_suffix       = 'radosgw.gateway',
  $ceph_rgw_hostname            = '',
  $ceph_rgw_dns_name            = '',
  $ceph_rgw_swift_url           = '',
  $ceph_backend_addrs           = [ ],
  $ceph_backend_names           = [ ],
) {

  include quickstack::pacemaker::common

  if str2bool_i(map_params('include_ceph')) {

    include ::quickstack::ceph::client_packages

    if str2bool_i("$ceph_manage_rgw") {

      include ::quickstack::ceph::rgw_packages

      Class['::quickstack::pacemaker::common']
      ->
      quickstack::pacemaker::vips { "ceph-gateway-vip":
        public_vip  => map_params("ceph_gateway_vip"),
        private_vip => map_params("ceph_gateway_vip"),
        admin_vip   => map_params("ceph_gateway_vip"),
      }

      if $ceph_backend_addrs == [ ] or !$ceph_backend_addrs {
        $_ceph_backend_addrs = map_params("lb_backend_server_addrs")
      } else {
        $_ceph_backend_addrs = $ceph_backend_addrs
      }

      if $ceph_backend_names == [ ] or !$ceph_backend_names {
        $_ceph_backend_names = map_params("lb_backend_server_names")
      } else {
        $_ceph_backend_names = $ceph_backend_names
      }

      class {"::quickstack::load_balancer::ceph_rgw":
        frontend_pub_host    => map_params("ceph_gateway_vip"),
        frontend_priv_host   => map_params("ceph_gateway_vip"),
        frontend_admin_host  => map_params("ceph_gateway_vip"),
        backend_server_names => $_ceph_backend_names,
        backend_server_addrs => $_ceph_backend_addrs,
      }
    }

    class { '::quickstack::ceph::config':
      manage_ceph_conf        => $ceph_manage_ceph_conf,
      fsid                    => $ceph_fsid,
      mon_initial_members     => $ceph_mon_initial_members,
      mon_host                => $ceph_mon_host,
      cluster_network         => $ceph_cluster_network,
      public_network          => $ceph_public_network,
      images_key              => $ceph_images_key,
      volumes_key             => $ceph_volumes_key,
      rgw_key                 => $ceph_rgw_key,
      conf_include_osd_global => $ceph_conf_include_osd_global,
      osd_pool_default_size   => $ceph_osd_pool_size,
      osd_journal_size        => $ceph_osd_journal_size,
      osd_mkfs_options_xfs    => $ceph_osd_mkfs_options_xfs,
      osd_mount_options_xfs   => $ceph_osd_mount_options_xfs,
      conf_include_rgw        => $ceph_conf_include_rgw,
      rgw_keyring_filename    => $ceph_rgw_keyring_filename,
      rgw_config_suffix       => $ceph_rgw_config_suffix,
      rgw_hostname            => $ceph_rgw_hostname,
      rgw_dns_name            => $ceph_rgw_dns_name,
      rgw_swift_url           => $ceph_rgw_swift_url,
    }
  }

}
