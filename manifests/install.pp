#
class foreman::install inherits foreman {

  $katello             = $foreman::katello

  $puppetdb            = $foreman::puppetdb
  $puppetdb_server     = $foreman::puppetdb_server
  $puppetdb_port       = $foreman::puppetdb_port

  $postgres_version    = $foreman::postgres_version

  $foreman_db_host     = $foreman::foreman_db_host
  $foreman_db_database = $foreman::foreman_db_database
  $foreman_db_username = $foreman::foreman_db_username
  $foreman_db_password = $foreman::foreman_db_password

  $override_options    = $foreman::override_options

  $puppetdb_server_real = $puppetdb_server ?
  {
    undef   => $::fqdn,
    default => $puppetdb_server
  }

  $puppetdb_port_real   = $puppetdb_port ?
  {
    undef   => 8081,
    default => $puppetdb_port
  }

  $puppetdb_schema = $puppetdb_port_real ?
  {
    8080    => 'http',
    8081    => 'https',
    default => 'https'
  }

  $puppetdb_address = "${puppetdb_schema}://${puppetdb_server_real}:${puppetdb_port_real}/pdb/cmd/v1"

  $db_is_local = (($foreman_db_host == undef) or ($foreman_db_host == 'localhost') or ($foreman_db_host == '127.0.0.1'))

  # Foreman installer packages
  # ------------------------------------------------------------------------
  $packages = $katello ?
  {
    true  => ['foreman-release-scl','katello'],
    false => ['foreman-release-scl','foreman-installer'],
  }

  package { $packages:
    ensure => installed,
  }

  # PostreSQL version
  # ------------------------------------------------------------------------
  if $db_is_local and defined(Class['puppetdb']) {

    if $postgres_version != $puppetdb::postgres_version {
      fail("\n\t if puppetdb is on the same host as foreman db then postgres_version must be set and equal to the one set for puppetdb \n")
    }

    ## Foreman tries to install PostreSQL from base OS repos while 
    ## puppetlabs-puppetdb module sets up official repo and installs more 
    ## up-to-date PostgreSQL version. To use it by Foreman as well:
    $file_line_defaults = {
      path    => '/etc/foreman-installer/custom-hiera.yaml',
      require => Package[$packages],
      before  => Exec['install foreman'],
    }

    file_line {
      default: * => $file_line_defaults;
      'postgresql version':
        line  => "postgresql::globals::version: '${postgres_version}'",
        match => '^postgresql::globals::version';
      'postgresql bindir':
        line  => "postgresql::globals::bindir: /usr/pgsql-${postgres_version}/bin",
        match => '^postgresql::globals::bindir';
    }
  }

  # Foreman installer options
  # ------------------------------------------------------------------------
  $scenario = $katello ?
  {
    true  => '--scenario katello',
    false => '',
  }

  $puppetdb_options = $puppetdb ?
  {
    true  => "--enable-foreman-plugin-puppetdb --foreman-plugin-puppetdb-address=${puppetdb_address}",
    false => '',
  }

  $foreman_db_options = $db_is_local ?
  {
    true  => '',
    false => @("END")
    --foreman-db-manage=false \
    --foreman-db-host=$foreman_db_host \
    --foreman-db-database=$foreman_db_database \
    --foreman-db-username=$foreman_db_username \
    --foreman-db-password=$foreman_db_password
    | END
  }

  $options = ! empty($override_options) ?
  {
    true  => join($override_options, ' '),
    false => '',
  }

  # Foreman installer run
  # ------------------------------------------------------------------------
  $foreman_installer_cmd = "foreman-installer ${scenario} --foreman-initial-admin-password=\"${password}\" ${puppetdb_options} ${foreman_db_options} ${options}"

  notify { "command: ${foreman_installer_cmd}": loglevel => warning }

  #exec { 'install foreman':
  #  command  => $foreman_installer_cmd,
  #  path     => $::path,
  #  unless   => '( which passenger-memory-stats 2>&1>/dev/null && passenger-memory-stats ) | grep "/usr/share/foreman"',
  #  provider => 'shell',
  #  timeout  => 0,
  #}

  ~> exec { 'wait 60 sec before foreman is stabilized':
    command     => 'sleep 60',
    path        => $::path,
    refreshonly => true,
    timeout     => 0,
  }

  # Fix access to PuppetDB certs
  # ------------------------------------------------------------------------
  if $puppetdb and ($puppetdb_server in ['localhost', '127.0.0.1', $::hostname, $::fqdn]) {
    user { 'foreman':
      ensure  => present,
      groups  => 'puppet',
      require => Exec['install foreman'],
      notify  => Exec['restart apache after foreman is added to puppet group'],
    }

    exec { 'restart apache after foreman is added to puppet group':
      command     => 'systemctl restart httpd',
      path        => $::path,
      refreshonly => true,
      require     => Exec['wait 60 sec before foreman is stabilized'],
    }
  }
}
