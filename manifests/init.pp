#
# @param password  Initial admin password in Foreman GUI
# @note  Some params come from module's hiera data directory.
#
class foreman (
  String  $foreman_release,
  String  $puppet_release,
  String  $katello_release,
  String  $password,
  Boolean $katello                     = true,
  Boolean $puppetdb                    = true,
  Boolean $r10k                        = true,
  Boolean $eyaml                       = true,
  Boolean $vault                       = false,
  String  $control_repo_url            = '',
  Boolean $plugin_discovery            = true,
  Boolean $plugin_remote_execution_ssh = true,
  Boolean $feature_bmc                 = true,
  Array   $compute_resources           = [],
) {

  class { 'foreman::repos':   } ->
  class { 'foreman::selinux': } ->
  class { 'foreman::puppet':  } ->
  class { 'foreman::install': }
}
