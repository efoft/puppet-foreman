#
class foreman::prepare inherits foreman {

  if $foreman::manage_hosts_entry {
    # In case there is no DNS at the momemt of server installation
    # DNS resolution is essential for Foreman installer
    host { $facts['networking']['fqdn']:
      ip           => $facts['networking']['ip'],
      host_aliases => $facts['networking']['hostname'],
    }
  }
}
