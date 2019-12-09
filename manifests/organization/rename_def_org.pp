#
class foreman::organization::rename_def_org (
  String $newname,
) {

  exec { "Rename Default Organization to ${newname}":
    command     => "hammer organization update --organization-label='Default_Organization' --new-name=\"${newname}\"",
    path        => $::path,
    unless      => "hammer organization info --name \"${newname}\"",
    environment => ['HOME=/root'],
    before      => Exec["Create organization ${newname}"],
    noop => true,
  }
}
