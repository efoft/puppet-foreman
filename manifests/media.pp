#
define foreman::media (
  String  $media         = $title,
  String  $os_family,
  String  $path,
  Array   $organizations = [],
  Array   $locations     = [],
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

  exec { "Create installation medium ${media}":
    command     => "hammer medium create --name \"${media}\" --os-family \"${os_family}\" --path \"${path}\" ${org} ${loc}",
    path        => $::path,
    unless      => "hammer medium info --name \"${media}\"",
    environment => ['HOME=/root'],
  }
}
