#
class foreman::install inherits foreman {

  $password            = $foreman::password

  $katello             = $foreman::katello

  $puppetdb            = $foreman::puppetdb
  $puppetdb_host       = $foreman::puppetdb_host
  $puppetdb_port       = $foreman::puppetdb_port

  $foreman_db_host     = $foreman::foreman_db_host
  $foreman_db_port     = $foreman::foreman_db_port
  $foreman_db_database = $foreman::foreman_db_database
  $foreman_db_username = $foreman::foreman_db_username
  $foreman_db_password = $foreman::foreman_db_password

  $katello_db_host     = $foreman::katello_db_host
  $katello_db_port     = $foreman::katello_db_port
  $katello_db_database = $foreman::katello_db_database
  $katello_db_username = $foreman::katello_db_username
  $katello_db_password = $foreman::katello_db_password

  $override_options    = $foreman::override_options

  $puppetdb_host_real = $puppetdb_host ?
  {
    undef   => $::fqdn,
    default => $puppetdb_host
  }

  $puppetdb_port_real = $puppetdb_port ?
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

  $puppetdb_address = "${puppetdb_schema}://${puppetdb_host_real}:${puppetdb_port_real}/pdb/cmd/v1"

  $foreman_db_port_real = $foreman_db_port ?
  {
    undef   => 5432,
    default => $foreman_db_port
  }
  $katello_db_port_real = $katello_db_port ?
  {
    undef   => 5432,
    default => $foreman_db_port
  }

  ## We assume db host is installed separately only if foreman_db_host was not set.
  ## Even it is set to localhost/127.0.0.1 this might mean e.g. remote db host is available via local haproxy.
  $db_is_local = ($foreman_db_host == undef)

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
    --foreman-db-host=${foreman_db_host} \
    --foreman-db-port=${foreman_db_port_real} \
    --foreman-db-database=${foreman_db_database} \
    --foreman-db-username=${foreman_db_username} \
    --foreman-db-password="${foreman_db_password}"
    |- END
  }

  $katello_db_options = ($katello and ! $db_is_local) ?
  {
    false => '',
    true  => @("END")
    --katello-candlepin-manage-db=false \
    --katello-candlepin-db-host=${katello_db_host} \
    --katello-candlepin-db-port=${katello_db_port_real} \
    --katello-candlepin-db-name=${katello_db_database} \
    --katello-candlepin-db-user=${katello_db_username} \
    --katello-candlepin-db-password="${katello_db_password}"
    |- END
  }

  $options = ! empty($override_options) ?
  {
    true  => join($override_options, ' '),
    false => '',
  }

  $installer_options = join([$puppetdb_options, $foreman_db_options, $katello_db_options, $options], ' ')

  # Foreman installer run
  # ------------------------------------------------------------------------
  ## LC_ALL is a workaround for the issues https://projects.theforeman.org/issues/25516, https://bugzilla.redhat.com/show_bug.cgi?id=1537632
  $foreman_installer_cmd = strip("foreman-installer -v ${scenario} --foreman-initial-admin-password=\"${password}\" ${installer_options}")
  $foreman_installer_md5 = md5($foreman_installer_cmd)

  exec { 'install foreman':
    command     => $foreman_installer_cmd,
    environment => ['LC_ALL=en_US.utf8'],
    path        => $::path,
    provider    => 'shell',
    timeout     => 0,
    unless      => "grep ${foreman_installer_md5} /etc/foreman-installer/.foreman-installer.status",
  }

  ~> exec { 'set foreman-installer status':
    command     => "echo -n ${foreman_installer_md5} > /etc/foreman-installer/.foreman-installer.status",
    path        => $::path,
    refreshonly => true,
    provider    => 'shell',
  }

  ~> exec { 'wait 60 sec before foreman is stabilized':
    command     => 'sleep 60',
    path        => $::path,
    refreshonly => true,
    timeout     => 0,
  }

  # Fix access to PuppetDB certs
  # ------------------------------------------------------------------------
  if $puppetdb and ($puppetdb_host_real in ['localhost', '127.0.0.1', $::hostname, $::fqdn]) {
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
