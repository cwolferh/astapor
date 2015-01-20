define quickstack::pacemaker::resource::generic(
  $clone_opts      = undef,
  $operation_opts  = undef,
  $resource_name   = "${title}",
  $resource_params = undef,
  $resource_type   = "systemd",
  $tries           = '4',
) {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    $_tmp_cib_file = "/tmp/cib-${title}"
    if $resource_name != "" {
      $_resource_name = ":${resource_name}"
    } else {
      $_resource_name = ""
    }

    if $clone_opts != undef {
      $_clone_opts = "--clone ${clone_opts}"
      $_pcs_name = "${title}-clone"
      $_pcs_update_command = "/usr/sbin/pcs -f ${_tmp_cib_file} resource clone ${title} ${clone_opts}"
    } else {
      $_clone_opts = ""
      $_pcs_name = "${title}"
      $_pcs_update_command = "/bin/true"
    }

    if $operation_opts != undef {
      $_operation_opts = "op ${operation_opts}"
    } else {
      $_operation_opts = ""
    }

    if $resource_params != undef {
      $_resource_params = "${resource_params}"
    } else {
      $_resource_params = ""
    }


    $pcs_command = "/usr/sbin/pcs -f ${_tmp_cib_file} resource create ${title} \
    ${resource_type}${_resource_name} ${_resource_params} ${_operation_opts}"

    $the_commands = "/usr/sbin/pcs cluster cib ${_tmp_cib_file}; ${pcs_command}; \
    ${_pcs_update_command}; /usr/sbin/pcs cluster cib-push ${_tmp_cib_file}" 

    anchor { "qprs start $name": }
    ->
    # We may need/want to set log level here?
    notify {"pcs command: ${title}":
      message => "running: ${pcs_command}",
    }
    ->
    # probably want to move this to puppet-pacemaker eventually
    exec {"create ${title} resource":
      command   => "${the_commands}",
      tries     => $tries,
      try_sleep => 30,
      unless    => "/usr/sbin/pcs resource show ${_pcs_name}"
    }
    ->
    exec {"wait for ${title} resource":
      timeout   => 3600,
      tries     => 360,
      try_sleep => 10,
      command   => "/usr/sbin/pcs resource show ${_pcs_name}",
    }
    ->
    # FIXME: All I can say is 'ICK'.  But this is what we were told to do by
    # pacemaker team.
    exec {"really wait for ${title} resource":
      path          => ["/usr/bin", "/usr/sbin", "/bin"],
      command => "sleep 5",
    }
    -> anchor { "qprs end ${title}": }
  }
}
