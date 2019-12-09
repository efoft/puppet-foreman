#
define foreman::template (
  String $template = $title,
  String $type,
  String $file,
) {

  exec { "Create template ${template}":
    command     => "hammer template create --name \"${template}\" --type ${type} --file \"${file}\"",
    path        => $::path,
    environment => ['HOME=/root'],
    unless      => "hammer template info --name \"${template}\"",
  }
}
