#
define foreman::config_group (
  String $group          = $title,
  Array  $puppet_classes = [],
  Array  $organizations  = [],
  Array  $locations      = [],
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

  ## upon config-group creation puppet classes might be not imported yet
  exec { "Create config group ${group}" :
    command     => "hammer config-group create --name ${group} ${org} ${loc}",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer config-group info --name ${group}",
  }

  ## update config group with puppet classes once they exist
  ## update puppet classes once they exists
  if ! empty($puppet_classes) {
    $_puppet_classes       = join($puppet_classes, ',')
    $_puppet_classes_regex = join($puppet_classes, '|') # for egrep
    $_puppet_classes_count = $puppet_classes.filter |$x| { $x =~ NotUndef }.length # alternative to stdlib's count()

    exec { "Set puppet classes ${_puppet_classes} for config group ${group}":
      command     => "hammer config-group update --hostgroup \"${group}\" --puppet-classes ${_puppet_classes}",
      path        => $::path,
      environment => ['HOME=/root'],
      onlyif      => "hammer config-group info --name \"${group}\" && [ $(hammer --csv puppet-class list | cut -f2 -d, | egrep \"^(${_puppet_classes_regex})$\" | wc -l) == ${_puppet_classes_count} ]",
      unless      => "hammer --csv --no-headers config-group info --name \"${group}\" --fields Puppetclasses | grep \"${_puppet_classes}\"",
    }
  }
}
