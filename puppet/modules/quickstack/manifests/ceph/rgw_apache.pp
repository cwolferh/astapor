class quickstack::ceph::rgw_apache (
  $declare_apache  = false,
  $vhost_addr      = '127.0.0.1',
  $listen_address  = '127.0.0.1',
  $servername      = $::fqdn,
  $serveradmin     = 'admin@localhost',
  $docroot         = '/var/www/html',
  $logroot         = '/var/log/httpd',
  $error_log_file  = 'error_log',
  $access_log_file = 'rgw_access.log',
) {

  if $declare_apache {
    class { 'apache':
      default_mods  => false,
      default_vhost => false,
    }

    # below class is really generic apache firewall
    class {'::quickstack::firewall::horizon':}
  }

  apache::vhost { $vhost_addr:
    servername      => $servername,
    serveradmin     => $serveradmin,
    docroot         => $docroot,
    error_log_file  => $error_log_file,
    access_log_file => $error_log_file,
    ip_based        => true,
    ip              => $bind_address,
    rewrites => [ {
      rewrite_rule  => ['^/(.*) /s3gw.fcgi?%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]']
      } ],
    directories     =>  [
      {
      'options'        => '+ExecCGI',
      'path'           => $docroot,
      'allow_override' => [ 'All' ],
      'sethandler'     => 'fastcgi-script',
      
      ##'auth_basic_authoritative' => 'Off', <- causing an apache error right now
      #
      # apache 2.4 and the vhost puppet template _directory prefers
      #   Require all granted
      # over Allow and Order directives
      #'allow'          => 'from all',
      #'order'          => 'Allow,Deny',
      } ,
    ]
         
  }
}
