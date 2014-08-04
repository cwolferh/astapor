class quickstack::pacemaker::ceph_config {

  include quickstack::pacemaker::common

  class { '::quickstack::ceph::config':
    fsid                => map_params('ceph_fsid'),
    mon_initial_members => map_params('ceph_mon_initial_members'),
    mon_host            => map_params('ceph_mon_host'),
    images_key          => map_params('ceph_images_key'),
    volumes_key         => map_params('ceph_volumes_key'),
  }
}