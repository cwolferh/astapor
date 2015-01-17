define quickstack::pacemaker::resource::service($group='',
                                                $clone=false,
                                                $interval='30s',
                                                $monitor_params=undef,
                                                $ensure='present',
                                                $options='') {
  include quickstack::pacemaker::params

  if has_interface_with("ipaddress", map_params("cluster_control_ip")){
    ::pacemaker::resource::service{ "$title":
                                group          => $group,
                                clone          => false,
                                interval       => $interval,
                                monitor_params => $monitor_params,
                                ensure         => $ensure,
                                options        => $options}

    anchor { "qprs start $title": }
    -> Pcmk_Resource["$title"]
    -> exec {"wait for pcmk_resource $title":
        timeout   => 3600,
        tries     => 360,
        try_sleep => 10,
        command   => "/usr/sbin/pcs resource show $title",
    }
    -> anchor { "qprs end $title": }

    if $clone {
      Exec["wait for pcmk_resource $title"] ->
      exec {"create pcmk_resource $title clone":
        command   => "/usr/sbin/pcs resource clone ${title}",
        unless    => "/usr/sbin/pcs resource show ${title}-clone",
        timeout   => 60,
        tries     => 5,
        try_sleep => 10,
      } ->
      exec {"wait for pcmk_resource ${title}-clone":
        timeout   => 3600,
        tries     => 360,
        try_sleep => 10,
        command   => "/usr/sbin/pcs resource show ${title}-clone",
      } ->
      Anchor["qprs end $title"]
    }
  }
}
