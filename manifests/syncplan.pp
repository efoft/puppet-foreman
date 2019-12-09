#
define foreman::syncplan (
  String                          $plan          = $title,
  Enum['weekly','hourly','daily'] $interval,
  Array                           $organizations,
  Boolean                         $enabled       = true,
  String                          $syncdate      = Timestamp.new().strftime('%F'),
) {

  $organizations.each |$org| {
    notice($plan)
    exec { "Create new sync-plan ${plan} for ${org}":
      command     => "hammer sync-plan create --organization \"${org}\" --name ${plan} --enabled ${enabled} --interval ${interval} --sync-date ${syncdate}",
      path        => $::path,
      unless      => "hammer sync-plan info --organization \"${org}\" --name \"${plan}\"",
      environment => ['HOME=/root'],
    }
  }
}
