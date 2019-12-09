#
define foreman::domain (
  String           $domain        = $title,
  Array            $organizations = [],
  Array            $locations     = [],
  Optional[String] $proxy         = undef,
) {

  $_organizations = join(suffix(prefix($organizations,'"'),'"'), ',')
  $org = empty($_organizations) ?
  {
    true  => '',
    false => "--organizations ${_organizations}",
  }

  $_locations = join(suffix(prefix($locations,'"'),'"'), ',')
  $loc = empty($_locations) ?
  {
    true  => '',
    false => "--locations ${_locations}",
  }

  exec { "Create domain ${domain}":
    command     => "hammer domain create --name \"${domain}\" ${org} ${loc}",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer domain info --name \"${domain}\"",
  }

  if $proxy {
    exec { "Set DNS-proxy ${proxy} for domain ${domain}":
      command     => "hammer domain update --name \"${domain}\" --dns ${proxy}",
      path        => $::path,
      environment => ['HOME=/root'],
      unless      => "hammer domain info --name \"${domain}\" --fields 'DNS Id' | egrep '[0-9]$'",
      onlyif      => "hammer --csv capsule list | grep ${proxy}",
    }
  }
}
