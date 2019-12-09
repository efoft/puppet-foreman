#
define foreman::partition_table (
  String $partition_table = $title,
  String $os_family,
  String $file,
  Array  $organizations   = [],
  Array  $locations       = [],
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

  exec { "Create partition table ${partition_table}":
    command     => "hammer partition-table create --name \"${partition_table}\" --os-family \"${os_family}\" --file \"${file}\" ${org} ${loc}",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer partition-table info --name \"${partition_table}\"",
  }
}
