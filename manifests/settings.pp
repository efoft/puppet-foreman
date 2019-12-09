#
define foreman::settings (
  String $param = $title,
  String $value,
) {

  exec { "Setting foreman parameter ${$param} to value ${value}":
    command     => "hammer settings set --name ${param} --value ${value}",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "[ $(hammer --csv settings list | grep '${param},' | cut -f3 -d,) == '${value}' ]",
  }
}
