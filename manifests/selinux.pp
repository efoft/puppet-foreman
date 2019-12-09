#
class foreman::selinux inherits foreman {

  # Disable SELinux
  exec { 'Put SELinux into permissive mode':
    command => 'setenforce 0',
    path    => $::path,
    unless  => "getenforce | egrep -i '(permissive|disabled)'",
  }
}
