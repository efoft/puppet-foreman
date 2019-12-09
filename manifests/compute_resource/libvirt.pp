#
define foreman::compute_resource::libvirt (
  String $resource      = $title,
  String $url,
  Array  $organizations = [],
  Array  $locations     = [],
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

  exec { "Create compute resource ${resource} of type libvirt":
    command     => "hammer compute-resource create --name \"${resource}\" --provider Libvirt --url \"${url}\" ${org} ${loc}",
    path        => $::path,
    unless      => "hammer compute-resource info --name \"${resource}\"",
    environment => ['HOME=/root'],
  }
}
