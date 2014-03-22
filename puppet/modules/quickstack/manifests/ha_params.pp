class quickstack::ha_params (

  # openstack services backend interface (used to determine the IP
  # that the services bind to)
  $backend_interface             = 'eth1',

  $manage_mysql                  = true,
  $manage_keystone               = true,
  $manage_glance                 = true,
  # ... ad infinitum

) { }


