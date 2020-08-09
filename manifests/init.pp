#
# @param password  Initial admin password in Foreman GUI
# @note  Some params come from module's hiera data directory.
#
class foreman (
  String                 $password,
  String                 $puppet_release,
  String                 $foreman_release,
  String                 $katello_release,
  Boolean                $katello             = true,
  # PuppetDB
  Boolean                $puppetdb            = true,
  Optional[Stdlib::Host] $puppetdb_host       = undef,
  Optional[Stdlib::Port] $puppetdb_port       = undef,
  # PostgreSQL
  Optional[String[1]]    $postgres_version    = undef,
  Optional[Stdlib::Host] $foreman_db_host     = undef,
  Optional[String[1]]    $foreman_db_database = undef,
  Optional[String[1]]    $foreman_db_username = undef,
  Optional[String[1]]    $foreman_db_password = undef,

  Boolean                $r10k                = true,
  Boolean                $eyaml               = true,
  Boolean                $vault               = false,
  String                 $control_repo_url    = '',

  Array                  $override_options    = [],
) {

  class { 'foreman::repos':   }
  -> class { 'foreman::prepare': }
  -> class { 'foreman::selinux': }
  -> class { 'foreman::puppet':  }
  -> class { 'foreman::install': }
}
