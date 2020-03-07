#
class foreman::puppet inherits foreman{

  # Puppetserver
  # -----------------------------------------------------------------------
  package { ['puppetserver','puppet-agent','puppet-bolt']:
    ensure => installed,
  }

  service { 'puppetserver':
    ensure  => running,
    enable  => true,
    require => Package['puppetserver'],
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
    package { 'hiera-eyaml':
      ensure          => installed,
      provider        => puppet_gem,
      install_options => [ '--no-document' ],
      notify          => Service['puppetserver'],
    }

    exec {
      default: * => $gem_install_exec_defaults;
      'install hiera-eyaml as puppetserver gem':
        command => '/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml  --no-document',
        unless  => '/opt/puppetlabs/bin/puppetserver gem list | grep hiera-eyaml';
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
        require => Package['puppetserver','puppet-agent'];
      '/root/.eyaml':
        ensure  => directory;
      '/root/.eyaml/config.yaml':
        ensure  => file,
        source  => 'puppet:///modules/foreman/eyaml_config.yaml';
      $eyaml_keys:
        ensure  => file,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0400';
    }

    exec { 'create eyaml keys':
      command => 'eyaml createkeys',
      path    => [$::path, '/opt/puppetlabs/puppet/bin'],
      creates => $eyaml_keys,
      before  => File[$eyaml_keys],
      require => Package['hiera-eyaml'],
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
    ->
    package { 'vault-puppetpath-gem':
      ensure          => 'present',
      name            => 'vault',
      provider        => 'puppet_gem',
      install_options => [ '--no-document' ],
    }
    ->
    package { 'debouncer-puppetserver-gem':
      ensure          => 'present',
      name            => 'debouncer',
      provider        => 'puppetserver_gem',
      install_options => [ '--no-document' ],
    }
    ->
    package { 'debouncer-puppetpath-gem':
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
    include puppetdb
    include puppetdb::master::config

    Class['puppetdb'] -> Class['puppetdb::master::config'] ~> Service['puppetserver']
  }
}
