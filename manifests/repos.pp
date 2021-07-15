#
class foreman::repos inherits foreman {

  $foreman_release  = $foreman::release
  $additional_repos = $foreman::additional_repos
  $katello          = $foreman::katello
  $katello_release  = $foreman::katello_release

  # EPEL (epel-release package is in built-in extras repository)
  exec { 'install epel-release for foreman':
    command => 'yum -y install epel-release',
    path    => $::path,
    unless  => 'rpm -q epel-release',
  }

  # Foreman release
  $foreman_rpm = "https://yum.theforeman.org/releases/${foreman_release}/el${facts['os']['release']['major']}/x86_64/foreman-release.rpm"

  exec { 'yum install foreman-release':
    command => "yum -y --nogpgcheck install ${foreman_rpm}",
    path    => $::path,
    unless  => 'rpm -q foreman-release',
  }

  # Additional repos
  if ! empty($additional_repos) {
    ensure_packages($additional_repos)
  }

  # Katello release
  if $katello {

    $katello_rpm = "https://yum.theforeman.org/katello/${katello_release}/katello/el${facts['os']['release']['major']}/x86_64/katello-repos-latest.rpm"

    exec { 'yum install katello-repos':
      command => "yum -y --nogpgcheck install ${katello_rpm}",
      path    => $::path,
      unless  => 'rpm -q katello-repos',
    }
  }
}
