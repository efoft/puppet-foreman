#
define foreman::repo (
  String                                       $repo            = $title,
  String                                       $org,
  String                                       $product,
  String                                       $url,
  Enum['on_demand','immediate','background']   $download_policy = 'on_demand',
  Enum['yes','no']                             $mirror_on_sync  = 'yes',
  Enum['yum','deb','puppet','docker','ostree'] $content_type    = 'yum',
) {

  exec { "Create new repo ${repo} for product ${product} in ${org}":
    command     => "hammer repository create --organization \"${org}\" --name \"${repo}\" --url \"${url}\" --product \"${product}\" --download-policy ${download_policy} --mirror-on-sync ${mirror_on_sync} --content-type ${content_type}",
    path        => $::path,
    unless      => "hammer repository info --organization \"${org}\" --product \"${product}\" --name \"${repo}\"",
    environment => ['HOME=/root'],
    require     => Exec["Create product ${product} in ${org}"],
    notify      => Exec["Sync repo ${repo} for product ${product} in ${org}"],
  }

  exec { "Sync repo ${repo} for product ${product} in ${org}":
    command     => "hammer repository synchronize --organization \"${org}\" --product \"${product}\" --async",
    path        => $::path,
    environment => ['HOME=/root'],
    refreshonly => true,
  }
}
