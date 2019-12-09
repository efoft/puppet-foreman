#
define foreman::product (
  String  $product       = $title,
  Array   $organizations,
  String  $syncplan,
  Hash    $repos         = {},
) {

  $organizations.each |$org| {
    exec { "Create product ${product} in ${org}":
      command     => "hammer product create --organization \"${org}\" --name \"${product}\" --sync-plan \"${syncplan}\"",
      path        => $::path,
      unless      => "hammer product info --organization \"${org}\" --name \"${product}\"",
      environment => ['HOME=/root'],
    }

    # To avoid duplicate declarations change names to unique ones
    $_repos = $repos.reduce({}) |$memo,$x| { $memo + { "Repo ${x[0]} for ${product} in ${org}" => { 'repo' => $x[0] } + $x[1] }}

    create_resources('foreman::repo', $_repos, { 'org' => $org, 'product' => $product })
  }
}
