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

  # r10k
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
      content => template('profile/foreman/r10k.yaml.erb'),
    }

    if empty($control_repo_url) {
      notify { 'No control repo URL is set in /etc/puppetlabs/r10k/r10k.yaml':
        loglevel => warning,
      }
    }
  }

  # hiera-eyaml
  # -----------------------------------------------------------------------
  if $eyaml {
    package { 'hiera-eyaml':
      ensure          => installed,
      provider        => puppet_gem,
      install_options => [ '--no-document' ],
    }

    exec { 'install hiera-eyaml as puppetserver gem':
      command => '/opt/puppetlabs/bin/puppetserver gem install hiera-eyaml  --no-document',
      path    => $::path,
      unless  => '/opt/puppetlabs/bin/puppetserver gem list | grep hiera-eyaml',
      require => Package['puppetserver'],
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
        source  => 'puppet:///modules/profile/foreman/eyaml_config.yaml';
      $eyaml_keys:
        ensure  => file,
        owner   => 'puppet',
        group   => 'puppet',
        mode    => '0400';
    }

    exec { 'create eyaml keys':
      command => 'eyaml createkeys',
      path    => $::path,
      creates => $eyaml_keys,
      before  => File[$eyaml_keys],
      require => Package['hiera-eyaml'],
    }
  }

  # Vault (TODO)
  # -----------------------------------------------------------------------
  
  # PuppetDB
  # -----------------------------------------------------------------------
  if $puppetdb {
    ## At the time being puppetdb module pulls stdlib 6.0 as a dependency 
    ## which turns not compatible with some other modules (like puppet-gitlab)
    exec { 'install stdlib 5.2.0 module':
      command => 'puppet module install puppetlabs-stdlib --version 5.2.0 -i /etc/puppetlabs/code/modules/',
      path    => [$::path, '/opt/puppetlabs/bin'],
      creates => '/etc/puppetlabs/code/modules/stdlib',
    }

    exec { 'install puppetdb module':
      command => 'puppet module install puppetlabs-puppetdb -i /etc/puppetlabs/code/modules',
      path    => [$::path, '/opt/puppetlabs/bin'],
      creates => '/etc/puppetlabs/code/modules/puppetdb',
    }

    class { 'puppetdb':
      require => Exec['install stdlib 5.2.0 module','install puppetdb module'],
    }->
    class { 'puppetdb::master::config':
      notify  => Service['puppetserver'],
    }
  }
}
