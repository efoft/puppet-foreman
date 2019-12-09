#
define foreman::activation_key (
  String $key           = $title,
  Array  $organizations,
  Array  $products,
) {

  $organizations.each |$org| {
    ensure_resource('Exec', "Activation key ${key} in ${org}",
    {
      'command'     => "hammer activation-key create --name \"${key}\" --organization=\"${org}\"",
      'path'        => $::path,
      'environment' => ['HOME=/root'],
      'unless'      => "hammer activation-key info --name \"${key}\" --organization \"${org}\"",
    })

    $products.each |$product| {
      exec { "Add subscription to activation key ${key} for ${product} in ${org}":
        command     => "hammer activation-key add-subscription --name \"${key}\" --organization \"${org}\" --subscription-id $(hammer --csv subscription list --organization \"${org}\" | grep \"${product}\" | cut -f1 -d,)",
        path        => $::path,
        unless      => "hammer --no-headers activation-key subscriptions --activation-key \"${key}\" --organization \"${org}\" | grep \"${product}\"",
        environment => ['HOME=/root'],
        require     => Exec["Activation key ${key} in ${org}"],
      }
    }
  }
}
