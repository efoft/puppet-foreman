#
# @param password            Initial admin password in Foreman GUI
# @param release             The Foreman release e.g. '2.1', '2.2' etc
# @param katello             If to use katello scenario for foreman-installer.
# @param puppetdb            If to install PuppetDB integration. This doesn't install PuppetDB itself.
# @param puppetdb_host       Specify if PuppetDB resides not on this host.
# @param puppetdb_port       Specify if PuppetDB resides not on this host.
# @param foreman_db_host     Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param foreman_db_port     Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param foreman_db_database Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param foreman_db_username Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param foreman_db_password Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param katello_db_host     Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param katello_db_port     Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param katello_db_database Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param katello_db_username Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param katello_db_password Specify only if PostgreSQL db is on external host and not managed by this manifest.
# @param r10k                If to install r10k gem to manage control repo.
# @param control_repo_url    The git URL of control repo (blank value leads to warning).
# @param eyaml               If to install and setup eyaml gem for sensitive data encryption.
# @param vault               If to install hiera_vault module to be able to retrieve data from Hashicorp Vault.
# @param manage_hosts_entry  If to add this host's FQDN into /etc/hosts if no DNS resolution is in place.
# @param override_options    Any other options foreman-installer accepts (see foreman-installer --full-help).
#
# @note  Some params come from module's hiera data directory.
# @note  Depending on the release number of The Foreman other params (like Katello release, repos etc) may vary.
#        All this is described in data/matrix.yaml and determined at compile time via hiera lookup.
#
class foreman (
  # Puppet & Foreman
  String                 $password,
  String                 $release             = 'latest',
  # Katello
  Boolean                $katello             = true,
  # PuppetDB
  Boolean                $puppetdb            = true,
  Optional[Stdlib::Host] $puppetdb_host       = undef,
  Optional[Stdlib::Port] $puppetdb_port       = undef,
  # Foreman Database
  Optional[Stdlib::Host] $foreman_db_host     = undef,
  Optional[Stdlib::Port] $foreman_db_port     = undef,
  Optional[String[1]]    $foreman_db_database = undef,
  Optional[String[1]]    $foreman_db_username = undef,
  Optional[String[1]]    $foreman_db_password = undef,
  # Katello Database
  Optional[Stdlib::Host] $katello_db_host     = undef,
  Optional[Stdlib::Port] $katello_db_port     = undef,
  Optional[String[1]]    $katello_db_database = undef,
  Optional[String[1]]    $katello_db_username = undef,
  Optional[String[1]]    $katello_db_password = undef,
  # Gems
  Boolean                $r10k                = true,
  String                 $control_repo_url    = '',
  Boolean                $eyaml               = true,
  Boolean                $vault               = false,
  # Misc
  Boolean                $manage_hosts_entry  = true,
  Array                  $override_options    = [],
) {

  if versioncmp($release, '2.0') < 0 {
    fail('minimal supported Foreman release is 2.0')
  }

  $matrix = lookup('foreman::matrix', Hash, 'hash', {})[$release]

  $katello_release = pick($matrix['katello_release'], 'latest')
  $extra_packages  = pick($matrix['extra_packages'], [])

  class { 'foreman::repos':   }
  -> class { 'foreman::prepare': }
  -> class { 'foreman::selinux': }
  -> class { 'foreman::puppet':  }
  -> class { 'foreman::install': }
}
