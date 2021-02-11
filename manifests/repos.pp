#
class foreman::repos inherits foreman {

  $puppet_release  = $foreman::puppet_release
  $foreman_release = $foreman::release

  $katello         = $foreman::katello
  $katello_release = $foreman::katello_release

  # enable CentOS extras repository
  ensure_packages('yum-utils')

  exec { 'enable extras repository for foreman':
    command => 'yum-config-manager --enable extras',
    path    => $::path,
    unless  => 'yum repolist -q | grep extras',
    require => Package['yum-utils'],
  }

  # Puppet
  $puppet_rpm = "https://yum.puppet.com/puppet${puppet_release}-release-el-${facts['os']['release']['major']}.noarch.rpm"

  exec { 'yum install puppet-release':
    command => "yum -y --nogpgcheck install ${puppet_rpm}",
    path    => $::path,
    unless  => "rpm -q puppet${puppet_release}-release",
    notify  => Exec['flush yum cache before foreman install'],
  }

  # Foreman
  $foreman_rpm = "https://yum.theforeman.org/releases/${foreman_release}/el${facts['os']['release']['major']}/x86_64/foreman-release.rpm"

  exec { 'yum install foreman-release':
    command => "yum -y --nogpgcheck install ${foreman_rpm}",
    path    => $::path,
    unless  => 'rpm -q foreman-release',
    notify  => Exec['flush yum cache before foreman install'],
  }

  # Katello
  if $katello {
    $katello_rpm = "https://fedorapeople.org/groups/katello/releases/yum/${katello_release}/katello/el${facts['os']['release']['major']}/x86_64/katello-repos-latest.rpm"

    exec { 'yum install katello-repos':
      command => "yum -y --nogpgcheck install ${katello_rpm}",
      path    => $::path,
      unless  => 'rpm -q katello-repos',
      notify  => Exec['flush yum cache before foreman install'],
    }
  }
}
