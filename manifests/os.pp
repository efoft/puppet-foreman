#
define foreman::os (
  String  $osname                = split($title,' ')[0],
  String  $major,
  String  $minor,
  String  $media,
  Array   $architectures         = ['x86_64'],
  String  $password_hash         = 'SHA512',
  String  $family,
  Array   $partition_tables,
  Array   $templates             = [],
  String  $provisioning_template = '',
) {


  $_architectures    = join($architectures, ',')
  $_partition_tables = join(suffix(prefix($partition_tables, '"'), '"'), ',')
  $_provisioning     = ! empty($provisioning_template) ?
  {
    true  => "--provisioning-templates \"${provisioning_template}\"",
    false => '',
  }

  $exec_defaults = {
    path        => $::path,
    environment => ['HOME=/root'],
  }

  # Create new or update existing OS
  # ---------------------------------------------------------------------------------------------------------------
  ## OS might already exist because of Foreman host itself
  exec {
    default: * => $exec_defaults;
    "Create OS ${title}":
      command => "hammer os create --name \"${osname}\" --major ${major} --minor ${minor} --media \"${media}\" --architectures ${_architectures} --password-hash ${password_hash} --family ${family} --partition-tables ${_partition_tables} ${_provisioning}",
      unless  => "hammer os info --title \"${title}\"";

    "Update OS ${title} with media ${media}":
      command => "hammer os update --title \"${title}\" --media \"${media}\"",
      onlyif  => "hammer os info --title \"${title}\"",
      unless  => "hammer os info --title \"${title}\" --fields 'Installation media' | egrep \"\s+${media}$\"";
  }
  
  ## update with partition tables
  $partition_tables.each |$ptable| {
    exec {
      default: * => $exec_defaults;
      "Update OS ${title} with partition-table ${ptable}":
        command => "hammer os update --title \"${title}\" --partition-tables ${_partition_tables}",
        onlyif  => "hammer os info --title \"${title}\"",
        unless  => "hammer os info --title \"${title}\" --fields 'Partition tables' | egrep \"${ptable}$\"";
    }
  }

  ## update with provisioning template
  if ! empty($provisioning_template) {
    exec {
      default: * => $exec_defaults;
      "Update OS ${title} with provisioning-template ${provisioning_template}":
        command => "hammer os update --title \"${title}\" ${_provisioning}",
        onlyif  => "hammer os info --title \"${title}\"",
        unless  => "hammer os info --title \"${title}\" --fields 'Templates' | egrep \"${provisioning_template}\\s+\\(\"";
    }
  }

  ## update with config template
  if ! empty($templates) {
    $templates.each |$tmpl| {
      exec {
        default: * => $exec_defaults;
        "Add config template ${tmpl} to OS ${title}":
        command => "hammer os add-config-template --title \"${title}\" --config-template \"${tmpl}\"",
        unless  => "hammer os info --title \"${title}\" --fields Templates | egrep \"${tmpl}\\s+\\(\"",
      }
    }
  }

  ## set default provisioning template
  exec {
    default: * => $exec_defaults;
    "Set default template ${provisioning_template} for ${title}":
      command => "hammer os set-default-template --id $(hammer --csv os list | grep \",${title},\" | cut -f1 -d,) --config-template-id $(hammer --csv template list | grep \",${provisioning_template},\" | cut -f1 -d,)",
      unless  => "hammer os info --title \"${title}\" --fields 'Default Templates' | egrep \"${provisioning_template}\\s+\\(\"";
  }
}
