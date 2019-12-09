#
define foreman::discovery_rule (
  String  $rule          = $title,
  Boolean $enabled       = true,
  String  $hostgroup,
  Integer $priority,
  String  $search,
  Array   $organizations = [],
  Array   $locations     = [],
) {

  ## organizations
  $_organizations = join(suffix(prefix($organizations,'"'),'"'), ',')
  $org = empty($_organizations) ?
  {
    true  => '',
    false => "--organizations ${_organizations}",
  }

  ## locations
  $_locations = join(suffix(prefix($locations,'"'),'"'), ',')
  $loc = empty($_locations) ?
  {
    true  => '',
    false => "--locations ${_locations}",
  }

  exec { "Create config group ${rule}" :
    command     => "hammer discovery-rule create --name ${rule} --enabled ${enabled} --priority ${priority} --hostgroup ${hostgroup} ${org} ${loc}",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer discovery-rule info --name ${rule}",
  }
}
