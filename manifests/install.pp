#
class foreman::install inherits foreman{

  # Foreman requires to resolve forward DNS for this host
  # ------------------------------------------------------------------------
  host { $::fqdn:
    host_aliases => $::hostname,
    ip           => $::ipaddress,
  }

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

  # PostreSQL Globals
  # ------------------------------------------------------------------------
  if $puppetdb {
    ## Foreman tries to install PostreSQL from base OS repos while 
    ## PuppetDB puppetlabs module already set up the repo and installed more 
    ## up-to-date PostgreSQL 9.6. To use it by Foreman as well:
    $file_line_defaults = {
      path    => '/etc/foreman-installer/custom-hiera.yaml',
      require => Package[$packages],
      before  => Exec['install foreman'],
    }

    file_line {
      default: * => $file_line_defaults;
      'postgresql version 9.6':
        line  => "postgresql::globals::version: '9.6'",
        match => '^postgresql::globals::version';
      'postgresql bindir 9.6':
        line  => "postgresql::globals::bindir: /usr/pgsql-9.6/bin",
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

  $compute_options = ! empty($compute_resources) ?
  {
    true  => join(prefix($compute_resources, '--enable-foreman-compute-'), ' '),
    false => '',
  }

  $puppetdb_options = $puppetdb ?
  {
    true  => "--enable-foreman-plugin-puppetdb --foreman-plugin-puppetdb-address=https://${fqdn}:8081/pdb/cmd/v1",
    false => '',
  }

  $discovery_options = $plugin_discovery ?
  {
    true  => '--enable-foreman-plugin-discovery --enable-foreman-proxy-plugin-discovery --enable-foreman-cli-discovery --foreman-proxy-plugin-discovery-install-images=true',
    false => '',
  }

  $remote_execution_ssh_options = $plugin_remote_execution_ssh ?
  {
    true  => '--enable-foreman-plugin-remote-execution --enable-foreman-proxy-plugin-remote-execution-ssh --foreman-proxy-plugin-remote-execution-ssh-install-key=true',
    false => '',
  }

  $bmc_options = $feature_bmc ?
  {
    true  => '--foreman-proxy-bmc=true',
    false => '',
  }

  # Foreman installer run
  # ------------------------------------------------------------------------
  $foreman_installer_cmd = "foreman-installer ${scenario} --foreman-initial-admin-password=\"${password}\" ${compute_options} ${puppetdb_options} ${discovery_options} ${bmc_options} ${remote_execution_ssh_options}"

  exec { 'install foreman':
    command  => $foreman_installer_cmd,
    path     => $::path,
    unless   => '( which passenger-memory-stats 2>&1>/dev/null && passenger-memory-stats ) | grep "/usr/share/foreman"',
    provider => 'shell',
    notify   => Exec['wait 60 sec before foreman is stabilized'],
    timeout  => 0,
  }

  exec { 'wait 60 sec before foreman is stabilized':
    command     => 'sleep 60',
    path        => $::path,
    refreshonly => true,
    timeout     => 0,
  }

  # Fix access to PuppetDB certs
  # ------------------------------------------------------------------------
  if $puppetdb {
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
