#
define foreman::organization (
  String $org = $title,
) {

  exec { "Create organization ${org}":
    command     => "hammer organization create --name \"${org}\"",
    path        => $::path,
    unless      => "hammer organization info --name \"${org}\"",
    environment => ['HOME=/root'],
    noop => true,
  }
}
