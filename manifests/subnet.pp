#
# @param boot_mode Default boot mode for interfaces assigned to this subnet
# @param ipam      IP Address auto suggestion mode for this subnet 
#
define foreman::subnet (
  String                            $subnet         = $title,
  String                            $network,
  String                            $mask,
  String                            $gateway,
  Array                             $dns            = [],
  Optional[Integer]                 $vlanid         = undef,
  Enum['DHCP','Static']             $boot_mode      = 'DHCP',
  Enum['DHCP','Internal DB','None'] $ipam           = 'None',
  Array                             $domains        = [],
  Array                             $organizations  = [],
  Array                             $locations      = [],
  Optional[String]                  $dns_proxy      = undef,
  Optional[String]                  $dhcp_proxy     = undef,
  Optional[String]                  $tftp_proxy     = undef,
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

  ## domains
  $_domains = join($domains, ',')
  $dom = empty($_domains) ?
  {
    true  => '',
    false => "--domains ${_domains}",
  }

  ## VLAN
  $_vlanid = $vlanid ? { undef => '', default => "--vlanid ${vlanid}" }

  ## DNS
  $dns_primary   = ($dns[0] != undef) ? { true => $dns[0], false => undef }
  $dns_secondary = ($dns[1] != undef) ? { true => $dns[1], false => undef }

  if $dns_primary and $dns_secondary {
    $_dns = "--dns-primary=${dns_primary} --dns-secondary=${dns_secondary}"
  }
  elsif $dns_primary {
    $_dns = "--dns-primary=${dns_primary}"
  }
  else {
    $_dns = ''
  }

  exec { "Create subnet ${subnet}":
    command     => "hammer subnet create --name \"${subnet}\" --network ${network} --mask ${mask} --gateway ${gateway} ${_dns} ${_vlanid} --ipam ${ipam} --boot-mode ${boot_mode} ${dom} ${org} ${loc}",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer subnet info --name \"${subnet}\"",
    noop        => true,
  }

  if $dns_proxy {
    exec { "Set DNS-proxy ${dns_proxy} for subnet ${subnet}":
      command     => "hammer subnet update --name \"${subnet}\" --dns ${dns_proxy}",
      path        => $::path,
      environment => ['HOME=/root'],
      unless      => "hammer subnet info --name \"${subnet}\" --fields 'Smart Proxies/DNS' | grep ${dns_proxy}",
      onlyif      => "hammer --csv capsule list | grep ${dns_proxy}",
      noop        => true,
    }
  }

  if $dhcp_proxy {
    exec { "Set DHCP-proxy ${dhcp_proxy} for subnet ${subnet}":
      command     => "hammer subnet update --name \"${subnet}\" --dhcp ${dhcp_proxy}",
      path        => $::path,
      environment => ['HOME=/root'],
      unless      => "hammer subnet info --name \"${subnet}\" --fields 'Smart Proxies/DHCP' | grep ${dhcp_proxy}",
      onlyif      => "hammer --csv capsule list | grep ${dhcp_proxy}",
      noop        => true,
    }
  }

  if $tftp_proxy {
    exec { "Set TFTP-proxy ${tftp_proxy} for subnet ${subnet}":
      command     => "hammer subnet update --name \"${subnet}\" --tftp ${tftp_proxy}",
      path        => $::path,
      environment => ['HOME=/root'],
      unless      => "hammer subnet info --name \"${subnet}\" --fields 'Smart Proxies/TFTP' | grep ${tftp_proxy}",
      onlyif      => "hammer --csv capsule list | grep ${tftp_proxy}",
      noop        => true,
    }
  }
}
