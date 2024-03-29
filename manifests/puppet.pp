#
class foreman::puppet inherits foreman{

  $r10k             = $foreman::r10k
  $control_repo_url = $foreman::control_repo_url
  $eyaml            = $foreman::eyaml
  $vault            = $foreman::vault
  $puppetdb         = $foreman::puppetdb
  $puppetdb_host    = $foreman::puppetdb_host
  $puppetdb_port    = $foreman::puppetdb_port

  # Puppetserver
  # -----------------------------------------------------------------------
  package { 'puppetserver':
    ensure => installed,
  }

  -> service { 'puppetserver':
    ensure => running,
    enable => true,
  }

  # Gems
  # -----------------------------------------------------------------------
  $gem_install_exec_defaults = {
    path    => $::path,
    require => Package['puppetserver'],
    notify  => Service['puppetserver'],
  }

  # gem: r10k
  # -----------------------------------------------------------------------
  if $r10k {
    package { 'r10k':
      ensure          => installed,
      provider        => puppet_gem,
      install_options => [ '--no-document' ],
    }

    file { ['/etc/puppetlabs/r10k','/var/cache/r10k']:
      ensure  => directory,
      require => Package['puppetserver'],
    }

    file { '/etc/puppetlabs/r10k/r10k.yaml':
      ensure  => file,
      content => template('foreman/r10k.yaml.erb'),
      replace => false,
    }

    if empty($control_repo_url) {
      notify { 'No control repo URL is set in /etc/puppetlabs/r10k/r10k.yaml':
        loglevel => warning,
      }
    }
  }

  # gem: hiera-eyaml
  # -----------------------------------------------------------------------
  if $eyaml {

    package { 'hiera-eyaml-puppetpath-gem':
      ensure          => 'present',
      name            => 'hiera-eyaml',
      provider        => 'puppetserver_gem',
      install_options => [ '--no-document' ],
    }

    -> package { 'hiera-eyaml':
      ensure          => installed,
      provider        => puppet_gem,
      install_options => [ '--no-document' ],
      notify          => Service['puppetserver'],
    }

    $eyaml_keys = [
      '/etc/puppetlabs/puppet/eyaml/public_key.pkcs7.pem',
      '/etc/puppetlabs/puppet/eyaml/private_key.pkcs7.pem'
    ]

    file {
      '/etc/puppetlabs/puppet/eyaml':
        ensure  => directory,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0500',
        require => Package['puppetserver'];
      '/root/.eyaml':
        ensure  => directory;
      '/root/.eyaml/config.yaml':
        ensure => file,
        source => 'puppet:///modules/foreman/eyaml_config.yaml';
      $eyaml_keys:
        ensure => file,
        owner  => 'puppet',
        group  => 'puppet',
        mode   => '0400';
    }

    exec { 'create eyaml keys':
      command => 'eyaml createkeys',
      path    => [$::path, '/opt/puppetlabs/puppet/bin'],
      creates => $eyaml_keys,
      before  => File[$eyaml_keys],
      require => [Package['hiera-eyaml'],File['/root/.eyaml/config.yaml']],
    }
  }

  # gem: vault (using https://github.com/petems/petems-hiera_vault)
  # -----------------------------------------------------------------------
  if $vault {

    package { 'vault-puppetserver-gem':
      ensure          => 'present',
      name            => 'vault',
      provider        => 'puppetserver_gem',
      install_options => [ '--no-document' ],
    }

    -> package { 'vault-puppetpath-gem':
      ensure          => 'present',
      name            => 'vault',
      provider        => 'puppet_gem',
      install_options => [ '--no-document' ],
    }

    -> package { 'debouncer-puppetserver-gem':
      ensure          => 'present',
      name            => 'debouncer',
      provider        => 'puppetserver_gem',
      install_options => [ '--no-document' ],
    }

    -> package { 'debouncer-puppetpath-gem':
      ensure          => 'present',
      name            => 'debouncer',
      provider        => 'puppet_gem',
      install_options => [ '--no-document' ],
    }
    ~> Service['puppetserver']

    exec { 'install petems/hiera_vault module':
      command => 'puppet module install petems/hiera_vault -i /etc/puppetlabs/code/modules/',
      path    => [$::path, '/opt/puppetlabs/bin'],
      creates => '/etc/puppetlabs/code/modules/hiera_vault',
      require => Package['puppet-agent'],
    }
  }

  # PuppetDB
  # -----------------------------------------------------------------------
  if $puppetdb {
    $puppetdb_disable_ssl = ($puppetdb_port == 8080)

    class {'puppetdb::master::config':
      puppetdb_server      => $puppetdb_host,
      puppetdb_port        => $puppetdb_port,
      puppetdb_disable_ssl => $puppetdb_disable_ssl,
    }

    Ini_setting['puppet.conf/master/storeconfigs'] ~> Service['puppetserver']


    ## In case PuppetDB is installed on the same host as puppet server...
    if defined(Class['puppetdb']) {

      ## PuppetDB fails to start if there's no ssl files in /etc/puppetlabs/puppet/ssl.
      ## These file are generated upon puppetserver start.
      ## We have to use exec instead of regular resource ordering because such ordering
      ## lead to dependency cycle due to the logic in puppetlabs-puppetdb code.

      exec { 'start puppetserver before puppetdb':
        command => 'systemctl start puppetserver',
        path    => $::path,
        unless  => 'systemctl is-active puppetserver',
        require => Package['puppetserver'],
        before  => Class['puppetdb'],
      }
    }
  }
}
