# @summary Request a certificate using the `certonly` installer
#
# This type can be used to request a certificate using the `certonly` installer.
#
# @param ensure
#   Intended state of the resource
#   Will remove certificates for specified domains if set to 'absent'. Will
#   also remove cronjobs and renewal scripts if `manage_cron` is set to 'true'.
# @param domains
#   An array of domains to include in the CSR.
# @param custom_plugin Whether to use a custom plugin in additional_args and disable -a flag.
# @param plugin The authenticator plugin to use when requesting the certificate.
# @param webroot_paths
#   An array of webroot paths for the domains in `domains`.
#   Required if using `plugin => 'webroot'`. If `domains` and
#   `webroot_paths` are not the same length, the last `webroot_paths`
#   element will be used for all subsequent domains.
# @param letsencrypt_command Command to run letsencrypt
# @param additional_args An array of additional command line arguments to pass to the `letsencrypt` command.
# @param environment  An optional array of environment variables
# @param key_size Size for the RSA public key
# @param manage_cron
#   Indicating whether or not to schedule cron job for renewal.
#   Runs daily but only renews if near expiration, e.g. within 10 days.
# @param suppress_cron_output Redirect cron output to devnull
# @param cron_before_command Representation of a command that should be run before renewal command
# @param cron_success_command Representation of a command that should be run if the renewal command succeeds.
# @param cron_hour
#   Optional hour(s) that the renewal command should execute.
#   e.g. '[0,12]' execute at midnight and midday.  Default - seeded random hour.
# @param cron_minute
#   Optional minute(s) that the renewal command should execute.
#   e.g. 0 or '00' or [0,30].  Default - seeded random minute.
# @param cron_monthday
#   Optional string, integer or array of monthday(s) the renewal command should
#   run. E.g. '2-30/2' to run on even days. Default: Every day.
# @param config_dir The path to the configuration directory.
# @param pre_hook_commands Array of commands to run in a shell before attempting to obtain/renew the certificate.
# @param post_hook_commands Array of command(s) to run in a shell after attempting to obtain/renew the certificate.
# @param deploy_hook_commands
#   Array of command(s) to run in a shell once if the certificate is successfully issued.
#   Two environmental variables are supplied by certbot:
#   - $RENEWED_LINEAGE: Points to the live directory with the cert files and key.
#                       Example: /etc/letsencrypt/live/example.com
#   - $RENEWED_DOMAINS: A space-delimited list of renewed certificate domains.
#                       Example: "example.com www.example.com"
#
define letsencrypt::certonly (
  Enum['present','absent']                  $ensure               = 'present',
  Array[String[1]]                          $domains              = [$title],
  String[1]                                 $cert_name            = $domains[0],
  Boolean                                   $custom_plugin        = false,
  Letsencrypt::Plugin                       $plugin               = 'standalone',
  Array[Stdlib::Unixpath]                   $webroot_paths        = [],
  String[1]                                 $letsencrypt_command  = $letsencrypt::command,
  Integer[2048]                             $key_size             = $letsencrypt::key_size,
  Array[String[1]]                          $additional_args      = [],
  Array[String[1]]                          $environment          = [],
  Boolean                                   $manage_cron          = false,
  Boolean                                   $suppress_cron_output = false,
  Optional[String[1]]                       $cron_before_command  = undef,
  Optional[String[1]]                       $cron_success_command = undef,
  Array[Variant[Integer[0, 59], String[1]]] $cron_monthday        = ['*'],
  Variant[Integer[0,23], String, Array]     $cron_hour            = fqdn_rand(24, $title),
  Variant[Integer[0,59], String, Array]     $cron_minute          = fqdn_rand(60, fqdn_rand_string(10, $title)),
  Stdlib::Unixpath                          $config_dir           = $letsencrypt::config_dir,
  Variant[String[1], Array[String[1]]]      $pre_hook_commands    = [],
  Variant[String[1], Array[String[1]]]      $post_hook_commands   = [],
  Variant[String[1], Array[String[1]]]      $deploy_hook_commands = [],
) {
  if $plugin == 'webroot' and empty($webroot_paths) {
    fail("The 'webroot_paths' parameter must be specified when using the 'webroot' plugin")
  }

  # Wildcard-less title for use in file paths
  $title_nowc = regsubst($title, '^\*\.', '')

  if $ensure == 'present' {
    if ($custom_plugin) {
      $default_args = "--text --agree-tos --non-interactive certonly --rsa-key-size ${key_size}"
    } else {
      $default_args = "--text --agree-tos --non-interactive certonly --rsa-key-size ${key_size} -a ${plugin}"
    }
  } else {
    $default_args = '--text --agree-tos --non-interactive delete'
  }

  case $plugin {
    'webroot': {
      $_plugin_args = zip($domains, $webroot_paths).map |$domain| {
        if $domain[1] {
          "--webroot-path ${domain[1]} -d '${domain[0]}'"
        } else {
          "-d '${domain[0]}'"
        }
      }
      $plugin_args = ["--cert-name '${cert_name}'"] + $_plugin_args
    }

    'dns-rfc2136': {
      require letsencrypt::plugin::dns_rfc2136
      $_domains = join($domains, '\' -d \'')
      $plugin_args = [
        "--cert-name '${cert_name}' -d",
        "'${_domains}'",
        "--dns-rfc2136-credentials ${letsencrypt::plugin::dns_rfc2136::config_dir}/dns-rfc2136.ini",
        "--dns-rfc2136-propagation-seconds ${letsencrypt::plugin::dns_rfc2136::propagation_seconds}",
      ]
    }

    'dns-route53': {
      require letsencrypt::plugin::dns_route53
      $_domains = join($domains, '\' -d \'')
      $plugin_args  = [
        "--cert-name '${cert_name}' -d '${_domains}'",
        "--dns-route53-propagation-seconds ${letsencrypt::plugin::dns_route53::propagation_seconds}",
      ]
    }

    default: {
      if $ensure == 'present' {
        $_domains = join($domains, '\' -d \'')
        $plugin_args  = "--cert-name '${cert_name}' -d '${_domains}'"
      } else {
        $plugin_args = "--cert-name '${cert_name}'"
      }
    }
  }

  $hook_args = ['pre', 'post', 'deploy'].map | String $type | {
    $commands = getvar("${type}_hook_commands")
    if (!empty($commands)) {
      $hook_file = "${config_dir}/renewal-hooks-puppet/${title_nowc}-${type}.sh"
      letsencrypt::hook { "${title}-${type}":
        type      => $type,
        hook_file => $hook_file,
        commands  => $commands,
        before    => Exec["letsencrypt certonly ${title}"],
      }
      "--${type}-hook \"${hook_file}\""
    }
    else {
      undef
    }
  }

  # certbot uses --cert-name to generate the file path
  $live_path_certname = regsubst($cert_name, '^\*\.', '')
  $live_path = "${config_dir}/live/${live_path_certname}/cert.pem"

  $_command = flatten([
      $letsencrypt_command,
      $default_args,
      $plugin_args,
      $hook_args,
      $additional_args,
  ]).filter | $arg | { $arg =~ NotUndef and $arg != [] }
  $command = join($_command, ' ')

  $verify_domains = join(unique($domains), '\' \'')

  if $ensure == 'present' {
    $exec_ensure = { 'unless' => "/usr/local/sbin/letsencrypt-domain-validation ${live_path} '${verify_domains}'" }
  } else {
    $exec_ensure = { 'onlyif' => "/usr/local/sbin/letsencrypt-domain-validation ${live_path} '${verify_domains}'" }
  }

  exec { "letsencrypt certonly ${title}":
    command     => $command,
    *           => $exec_ensure,
    path        => $facts['path'],
    environment => $environment,
    provider    => 'shell',
    require     => [
      Class['letsencrypt'],
      File['/usr/local/sbin/letsencrypt-domain-validation'],
    ],
  }

  if $manage_cron {
    $maincommand = join(["${letsencrypt_command} --keep-until-expiring"] + $_command[1,-1], ' ')
    $cron_script_ensure = $ensure ? { 'present' => 'file', default => 'absent' }
    $cron_ensure = $ensure

    if $suppress_cron_output {
      $croncommand = "${maincommand} > /dev/null 2>&1"
    } else {
      $croncommand = $maincommand
    }
    if $cron_before_command {
      $renewcommand = "(${cron_before_command}) && ${croncommand}"
    } else {
      $renewcommand = $croncommand
    }
    if $cron_success_command {
      $cron_cmd = "${renewcommand} && (${cron_success_command})"
    } else {
      $cron_cmd = $renewcommand
    }

    file { "${letsencrypt::cron_scripts_path}/renew-${title}.sh":
      ensure  => $cron_script_ensure,
      mode    => '0755',
      owner   => 'root',
      group   => $letsencrypt::cron_owner_group,
      content => template('letsencrypt/renew-script.sh.erb'),
    }

    cron { "letsencrypt renew cron ${title}":
      ensure   => $cron_ensure,
      command  => "\"${letsencrypt::cron_scripts_path}/renew-${title}.sh\"",
      user     => root,
      hour     => $cron_hour,
      minute   => $cron_minute,
      monthday => $cron_monthday,
    }
  }
}
