class quickstack::pacemaker::constraints() {

  include quickstack::pacemaker::common

  anchor {'pacemaker ordering constraints begin': }

  if (str2bool_i(map_params('include_keystone'))) {
    quickstack::pacemaker::constraint::base_services{"base-then-keystone-constr" :
      target_resource => "openstack-keystone-clone",
    }
  }

  if (str2bool_i(map_params('include_glance'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-glance-constr' :
        first_resource  => "openstack-keystone-clone",
        second_resource => "openstack-glance-registry-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-glance-constr" :
        target_resource => "openstack-glance-registry-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_cinder'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-cinder-constr' :
        first_resource  => "openstack-keystone-clone",
        second_resource => "openstack-cinder-api-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-cinder-constr" :
        target_resource => "openstack-cinder-api-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_swift'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-swift-constr' :
        first_resource  => "openstack-keystone-clone",
        second_resource => "openstack-swift-proxy",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-swift-constr" :
        target_resource => "openstack-swift-proxy",
      }     
    }
  }

  if (str2bool_i(map_params('include_nova'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-nova-constr' :
        first_resource  => "openstack-keystone-clone",
        second_resource => "openstack-nova-consoleauth-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-nova-constr" :
        target_resource => "openstack-nova-consoleauth-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_neutron'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-neutron-constr' :
        first_resource  => "openstack-keystone-clone",
        second_resource => "neutron-server-clone",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-neutron-constr" :
        target_resource => "neutron-server-clone",
      }     
    }
  }

  if (str2bool_i(map_params('include_ceilometer'))) {
    if (str2bool_i(map_params('include_keystone'))) {
      quickstack::pacemaker::constraint::typical{ 'keystone-then-ceilometer-constr' :
        first_resource  => "openstack-keystone-clone",
        second_resource => "openstack-ceilometer-central",
        colocation      => false,
      }
    } else {
      quickstack::pacemaker::constraint::base_services{"base-then-ceilo-constr" :
        target_resource => "openstack-ceilometer-central",
      }     
    }
    if (str2bool_i(map_params('include_nosql'))) {
      quickstack::pacemaker::constraint::typical{ 'mongod-then-ceilometer-constr' :
        first_resource  => "mongod-clone",
        second_resource => "openstack-ceilometer-central",
        colocation      => false,
      }
    }
  }

  anchor {'pacemaker ordering constraints end': }
}
