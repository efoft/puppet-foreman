#
# @param password            Initial admin password in Foreman GUI
# @param puppet_release      Default: 6 comes from module's hiera
# @param foreman_release     Default: 2.1 comes from module's hiera
# @param katello             If to use katello scenario for foreman-installer.
# @param katello_release     Default: 3.15 comes from module's hiera
# @param puppetdb            If to install PuppetDB integration. This doesn't install PuppetDB itself.
# @param puppetdb_host       Specify if PuppetDB resides not on this host.
# @param puppetdb_port       Specify if PuppetDB resides not on this host.
# @param postgres_version    Version to be set in custom-install.yml of foreman-installer. But doen't manage PostreSQL repos!
# @param foreman_db_host     Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param foreman_db_database Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param foreman_db_username Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param foreman_db_password Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param r10k                If to install r10k gem to manage control repo.
# @param control_repo_url    The git URL of control repo (blank value leads to warning).
# @param eyaml               If to install and setup eyaml gem for sensitive data encryption.
# @param vault               If to install hiera_vault module to be able to retrieve data from Hashicorp Vault.
# @param manage_hosts_entry  If to add this host's FQDN into /etc/hosts if no DNS resolution is in place.
#
# @note  Some params come from module's hiera data directory.
#
class foreman (
  # Puppet & Foreman
  String                 $password,
  String                 $puppet_release,
  String                 $foreman_release,
  # Katello
  Boolean                $katello             = true,
  String                 $katello_release,
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
  # Gems
  Boolean                $r10k                = true,
  String                 $control_repo_url    = '',
  Boolean                $eyaml               = true,
  Boolean                $vault               = false,
  # Misc
  Boolean                $manage_hosts_entry  = true,
  Array                  $override_options    = [],
) {

  class { 'foreman::repos':   }
  -> class { 'foreman::prepare': }
  -> class { 'foreman::selinux': }
  -> class { 'foreman::puppet':  }
  -> class { 'foreman::install': }
}
