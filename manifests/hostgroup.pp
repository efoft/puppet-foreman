#
define foreman::hostgroup (
  String              $hostgroup             = $title,
  Optional[String]    $architecture          = undef,
  Optional[String]    $content_source        = undef,
  Optional[String]    $content_view          = undef,
  Optional[String]    $description           = undef,
  Optional[String]    $domain                = undef,
  Optional[String]    $lifecycle_environment = undef,
  Optional[String]    $medium                = undef,
  Optional[String]    $operatingsystem       = undef,
  Optional[String]    $parent                = undef,
  Optional[String]    $partition_table       = undef,
  Optional[String]    $puppet_ca_proxy       = undef,
  Optional[String]    $puppet_proxy          = undef,
  Optional[String]    $puppet_environment    = undef,
  Optional[String]    $pxe_loader            = undef,
  Optional[String]    $root_pass             = undef,
  Optional[String]    $subnet                = undef,
  Optional[Array]     $activation_keys       = undef,
  Optional[Array]     $locations             = undef,
  Optional[Array]     $organizations         = undef,
  Hash                $group_parameters      = {},
  Array               $config_groups         = [],
  Array               $puppet_classes        = [],
) {

  $_architecture          = $architecture          ? { undef => '', default => "--architecture ${architecture}" }
  $_content_source        = $content_source        ? { undef => '', default => "--content-source ${content_source}" }
  $_content_view          = $content_view          ? { undef => '', default => "--content-view \"${content_view}\"" }
  $_description           = $description           ? { undef => '', default => "--description \"${description}\"" }
  $_domain                = $domain                ? { undef => '', default => "--domain ${domain}" }
  $_lifecycle_environment = $lifecycle_environment ? { undef => '', default => "--lifecycle-environment \"${lifecycle_environment}\"" }
  $_medium                = $medium                ? { undef => '', default => "--medium \"${medium}\"" }
  $_operatingsystem       = $operatingsystem       ? { undef => '', default => "--operatingsystem \"${operatingsystem}\"" }
  $_parent                = $parent                ? { undef => '', default => "--parent ${parent}" }
  $_partition_table       = $partition_table       ? { undef => '', default => "--partition-table \"${partition_table}\"" }
  $_puppet_ca_proxy       = $puppet_ca_proxy       ? { undef => '', default => "--puppet-ca-proxy ${puppet_ca_proxy}" }
  $_puppet_proxy          = $puppet_proxy          ? { undef => '', default => "--puppet-proxy ${puppet_proxy}" }
  $_puppet_environment    = $puppet_environment    ? { undef => '', default => "--puppet-environment ${puppet_environment}" }
  $_pxe_loader            = $pxe_loader            ? { undef => '', default => "--pxe-loader \"${pxe_loader}\"" }
  $_root_pass             = $root_pass             ? { undef => '', default => "--root-pass \"${root_pass}\"" }
  $_subnet                = $subnet                ? { undef => '', default => "--subnet \"${subnet}\"" }

  ## organizations
  if $organizations {
    $org = join(suffix(prefix($organizations,'"'),'"'), ',')
    $_organizations = "--organizations ${org}"
  }
  else {
    $_organizations = ''
  }

  ## locations
  if $locations {
    $loc = join(suffix(prefix($locations,'"'),'"'), ',')
    $_locations = "--locations ${loc}"
  }
  else {
    $_locations = ''
  }

  ## activation keys => they must be appended to hostgroup-parameters
  $kt_activation_keys = $activation_keys ?
  {
    undef   => {},
    default => { 'kt_activation_keys' => join($activation_keys, ',') },
  }

  $_group_parameters  = $group_parameters + $kt_activation_keys
  
  ## config group
  $_config_groups = join($config_groups, ',')
  $_groups = empty($_config_groups) ?
  {
    true  => '',
    false => "--config-groups ${_config_groups}",
  }

  $command = "hammer hostgroup create --name \"${hostgroup}\" ${_architecture} ${_content_source} ${_content_view} ${_description} ${_domain} ${_lifecycle_environment} ${_medium} ${_operatingsystem} ${_parent} ${_partition_table} ${_puppet_ca_proxy} ${_puppet_proxy} ${_puppet_environment} ${_pxe_loader} ${_root_pass} ${_subnet} ${_groups} ${_organizations} ${_locations}"

  exec { "Create hostgroup ${hostgroup}":
    command     => $command,
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer hostgroup info --name \"${hostgroup}\"",
  }

  ## group parameters
  if ! empty($_group_parameters) {
    $_group_parameters.each |$k,$v| {
      if $v =~ Boolean {
        $type = 'boolean'
      }
      elsif $v =~ Integer {
        $type = 'integer'
      }
      else {
        $type = 'string'
      }
      
      exec { "Setting parameter ${k} to ${v} for hostgroup ${hostgroup}":
        command     => "hammer hostgroup set-parameter --hostgroup \"${hostgroup}\" --name ${k} --parameter-type ${type} --value ${v}",
        path        => $::path,
        environment => ['HOME=/root'],
        unless      => "hammer hostgroup info --name \"${hostgroup}\" --fields Parameters | grep \'${k} => ${v}\'",
      }
    }
  }

  ## update puppet classes once they exists
  if ! empty($puppet_classes) {
    $_puppet_classes       = join($puppet_classes, ',')
    $_puppet_classes_regex = join($puppet_classes, '|') # for egrep
    $_puppet_classes_count = $puppet_classes.filter |$x| { $x =~ NotUndef }.length # alternative to stdlib's count()
 
    exec { "Set puppet classes ${_puppet_classes} for group ${hostgroup}":
      command     => "hammer hostgroup update --hostgroup \"${hostgroup}\" --puppet-classes ${_puppet_classes}",
      path        => $::path,
      environment => ['HOME=/root'],
      onlyif      => "hammer hostgroup info --name \"${hostgroup}\" && [ $(hammer --csv puppet-class list | cut -f2 -d, | egrep \"^(${_puppet_classes_regex})$\" | wc -l) == ${_puppet_classes_count} ]", 
      unless      => "hammer --csv --no-headers hostgroup info --name \"${hostgroup}\" --fields Puppetclasses | grep \"${_puppet_classes}\"",
    }
  }
}
