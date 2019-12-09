#
# @param password  Initial admin password in Foreman GUI
#
class foreman (
  Boolean $katello                     = true,
  Boolean $puppetdb                    = true,
  Boolean $r10k                        = true,
  Boolean $eyaml                       = true,
  Boolean $vault                       = false,
  String  $foreman_release             = '1.23',
  String  $puppet_release              = '6',
  String  $katello_release             = '3.13',
  String  $control_repo_url            = '',
  Boolean $plugin_discovery            = true,
  Boolean $plugin_remote_execution_ssh = true,
  Boolean $feature_bmc                 = true,
  Array   $compute_resources           = [],
  String  $password,
) {

  class { 'foreman::repos':   } ->
  class { 'foreman::selinux': } ->
  class { 'foreman::puppet':  } ->
  class { 'foreman::install': }
}
