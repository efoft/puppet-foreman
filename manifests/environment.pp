#
define foreman::environment (
  String $environment = $title,
) {

  exec { "create puppet environment ${environment}":
    command     => "hammer puppet-environment create --name \"${environment}\"",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer puppet-environment info --name  \"${environment}\"",
  }
}
