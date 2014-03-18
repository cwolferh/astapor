class quickstack::pacemaker::glance (
  $user_password,   # the keystone password for the keystone user, 'glance'
  $db_password,
  $db_host                  = '127.0.0.1',
  $keystone_host            = '127.0.0.1',
  $sql_idle_timeout         = '3600',
  $registry_host            = '0.0.0.0',
  $bind_host                = '0.0.0.0',
  $db_ssl                   = false,
  $db_ssl_ca                = undef,
  $db_user                  = 'glance',
  $db_name                  = 'glance',
  $backend                  = 'file',
  # this manifest is responsible for mounting the 'file' $backend
  # through pacemaker
  $pcmk_fs_manage           = 'true',
  # if $backend is 'file' and $pcmk_fs_manage is true,
  # then make sure other pcmk_fs_ params are correct
  $pcmk_fs_type             = 'nfs',
  $pcmk_fs_device           = '/shared/storage/device',
  $pcmk_fs_dir              = '/var/lib/glance/images/',
  # if keystone is run on the same local pacemaker cluster (then it
  # must be running before we attempt setting up glance)
  $pcmk_keystone_is_local   = true,
  # if $backend is 'swift' *and* swift is run on the same local
  # pacemaker cluster (as opposed to swift proxies being remote)
  $pcmk_swift_is_local      = true,
  $rbd_store_user           = '',
  $rbd_store_pool           = 'images',
  $swift_store_user         = '',
  $swift_store_key          = '',
  $swift_store_auth_address = 'http://127.0.0.1:5000/v2.0/',
  $verbose                  = false,
  $debug                    = false,
  $use_syslog               = false,
  $log_facility             = 'LOG_USER',
  $enabled                  = true,
  $filesystem_store_datadir = '/var/lib/glance/images/',
) inherits quickstack::params {

  include quickstack::pacemaker::common

  if str2bool_i("$pcmk_keystone_is_local") {
    Class['::quickstack::pacemaker::keystone'] ->
    Class['::quickstack::pacemaker::glance']
  }

  if($backend == 'swift') {
    if str2bool_i("$pcmk_swift_is_local") {
      Class['::quickstack::pacemaker::swift'] ->
      Class['::quickstack::pacemaker::glance']
    }
  } elsif ($backend == 'file') {
    if str2bool_i("$pcmk_fs_manage") {
      pacemaker::resource::filesystem { "glance fs":
        device => $pcmk_fs_device,
        directory => $pcmk_fs_dir,
        fstype => $pcmk_fs_type,
	clone  => true,
      }
      -> Class['::quickstack::glance']
    }
  }

  class { 'quickstack::glance':
    user_password            => $user_password,
    db_password              => $db_password,
    db_host                  => $db_host,
    keystone_host            => $keystone_host,
    sql_idle_timeout         => $sql_idle_timeout,
    registry_host            => $registry_host,
    bind_host                => $bind_host,
    db_ssl                   => $db_ssl,
    db_ssl_ca                => $db_ssl_ca,
    db_user                  => $db_user,
    db_name                  => $db_name,
    backend                  => $backend,
    rbd_store_user           => $rbd_store_user,
    rbd_store_pool           => $rbd_store_pool,
    swift_store_user         => $swift_store_user,
    swift_store_key          => $swift_store_key,
    swift_store_auth_address => $swift_store_auth_address,
    verbose                  => $verbose,
    debug                    => $debug,
    use_syslog               => $use_syslog,
    log_facility             => $log_facility,
    enabled                  => $enabled,
    filesystem_store_datadir => $filesystem_store_datadir,
  }

  Class['::quickstack::pacemaker::common'] ->
  Class['::quickstack::pacemaker::glance']
}
