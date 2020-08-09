#
class foreman::repos inherits foreman {

  $puppet_release  = $foreman::puppet_release
  $foreman_release = $foreman::foreman_release

  $katello         = $foreman::katello
  $katello_release = $foreman::katello_release

  # EPEL (epel-release package is in built-in extras repository)
  exec { 'install epel-release for foreman':
    command => 'yum -y install epel-release',
    path    => $::path,
    unless  => 'rpm -q epel-release',
  }

  # Puppet
  $puppet_rpm = "https://yum.puppet.com/puppet${puppet_release}-release-el-${facts['os']['release']['major']}.noarch.rpm"

  exec { 'yum install puppet-release':
    command => "yum -y --nogpgcheck install ${puppet_rpm}",
    path    => $::path,
    unless  => "rpm -q puppet${puppet_release}-release",
  }

  # Foreman
  $foreman_rpm = "https://yum.theforeman.org/releases/${foreman_release}/el${facts['os']['release']['major']}/x86_64/foreman-release.rpm"

  exec { 'yum install foreman-release':
    command => "yum -y --nogpgcheck install ${foreman_rpm}",
    path    => $::path,
    unless  => 'rpm -q foreman-release',
  }

  # Katello
  if $katello {
    $katello_rpm = "https://fedorapeople.org/groups/katello/releases/yum/${katello_release}/katello/el${facts['os']['release']['major']}/x86_64/katello-repos-latest.rpm"

    exec { 'yum install katello-repos':
      command => "yum -y --nogpgcheck install ${katello_rpm}",
      path    => $::path,
      unless  => 'rpm -q katello-repos',
    }
  }
}
