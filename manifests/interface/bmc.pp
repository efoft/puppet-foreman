#
define foreman::interface::bmc (
  String           $identifier = $title,
  String           $host,
  Optional[String] $mac        = undef,
  Optional[String] $ip         = undef,
  Optional[String] $username   = undef,
  Optional[String] $password   = undef,
) {

  $_mac      = $mac      ? { undef => '', default => "--mac ${mac}" }
  $_ip       = $ip       ? { undef => '', default => "--ip ${ip}" }
  $_username = $username ? { undef => '', default => "--username \"${username}\"" }
  $_password = $password ? { undef => '', default => "--password \"${password}\"" }

  exec { "Create BMC interface ${identifier} on host ${host}":
    command     => "hammer host interface create --host ${host} --identifier ${identifier} --type bmc --provider IPMI ${_mac} ${_ip} ${_username} ${_password}",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer --csv host interface list --host ${host} | grep \",${identifier},\"",
  }

  # we update only user/password
  if $username and $password {
    exec { "Update BMC interface ${identifier} on host ${host}":
      command     => "hammer host interface update --host ${host} --identifier ${identifier} --type bmc --provider IPMI ${_mac} ${_ip} ${_username} ${_password} --id $(hammer --csv host interface list --host ${host} | grep \",${identifier},\" | cut -f1 -d,)",
      path        => $::path,
      environment => ['HOME=/root'],
      onlyif      => "hammer --csv host interface list --host ${host} | grep \",${identifier},\"",
      unless      => "hammer --csv --no-headers host interface info --host ${host} --id $(hammer --csv host interface list --host ${host} | grep \",${identifier},\" | cut -f1 -d,) --fields BMC/Username | egrep '^${username}$'",
    }
  }
}
