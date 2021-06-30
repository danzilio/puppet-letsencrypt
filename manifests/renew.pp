# @summary Configures renewal of Let's Encrypt certificates using Certbot
#
# Configures renewal of Let's Encrypt certificates using the certbot renew command.
#
# Note: Hooks set here will run before/after/for ALL certificates, including
# any not managed by Puppet. If you want to create hooks for specific
# certificates only, create them using letsencrypt::certonly.
#
# @param pre_hook_commands Array of commands to run in a shell before obtaining/renewing any certificates.
# @param post_hook_commands Array of commands to run in a shell after attempting to obtain/renew certificates.
# @param deploy_hook_commands
#   Array of commands to run in a shell once for each successfully issued/renewed
#   certificate. Two environmental variables are supplied by certbot:
#   - $RENEWED_LINEAGE: Points to the live directory with the cert files and key.
#                       Example: /etc/letsencrypt/live/example.com
#   - $RENEWED_DOMAINS: A space-delimited list of renewed certificate domains.
#                       Example: "example.com www.example.com"
# @param additional_args Array of additional command line arguments to pass to 'certbot renew'.
# @param cron_ensure Intended state of the cron resource running certbot renew
# @param cron_hour
#   Optional string, integer or array of hour(s) the renewal command should run.
#   E.g. '[0,12]' to execute at midnight and midday. Default: fqdn-seeded random hour.
# @param cron_minute
#   Optional string, integer or array of minute(s) the renewal command should
#   run. E.g. 0 or '00' or [0,30]. Default: fqdn-seeded random minute.
# @param cron_monthday
#   Optional string, integer or array of monthday(s) the renewal command should
#   run. E.g. '2-30/2' to run on even days. Default: Every day.
# @param hook_file_owner_group
#   Set the group ownership of the pushed hook files
#
class letsencrypt::renew (
  Variant[String[1], Array[String[1]]] $pre_hook_commands     = $letsencrypt::renew_pre_hook_commands,
  Variant[String[1], Array[String[1]]] $post_hook_commands    = $letsencrypt::renew_post_hook_commands,
  Variant[String[1], Array[String[1]]] $deploy_hook_commands  = $letsencrypt::renew_deploy_hook_commands,
  Array[String[1]]                     $additional_args       = $letsencrypt::renew_additional_args,
  Enum['present', 'absent']            $cron_ensure           = $letsencrypt::renew_cron_ensure,
  Letsencrypt::Cron::Hour              $cron_hour             = $letsencrypt::renew_cron_hour,
  Letsencrypt::Cron::Minute            $cron_minute           = $letsencrypt::renew_cron_minute,
  Letsencrypt::Cron::Monthday          $cron_monthday         = $letsencrypt::renew_cron_monthday,
  String                               $hook_file_owner_group = $letsencrypt::root_file_owner_group,
) {
  # Directory used for Puppet-managed renewal hooks. Make sure old unmanaged
  # hooks in this directory are purged. Leave custom hooks in the default
  # renewal-hooks directory alone.
  file { 'letsencrypt-renewal-hooks-puppet':
    ensure  => directory,
    path    => "${letsencrypt::config_dir}/renewal-hooks-puppet",
    owner   => 'root',
    group   => $hook_file_owner_group,
    mode    => '0755',
    recurse => true,
    purge   => true,
  }

  $default_args = 'renew -q'

  $hook_args = ['pre', 'post', 'deploy'].map | String $type | {
    $commands = getvar("${type}_hook_commands")
    if (!empty($commands)) {
      $hook_file = "${letsencrypt::config_dir}/renewal-hooks-puppet/renew-${type}.sh"
      letsencrypt::hook { "renew-${type}":
        type      => $type,
        hook_file => $hook_file,
        commands  => $commands,
      }
      "--${type}-hook \"${hook_file}\""
    }
    else {
      undef
    }
  }

  $_command = flatten([
      $letsencrypt::command,
      $default_args,
      $hook_args,
      $additional_args,
  ]).filter | $arg | { $arg =~ NotUndef and $arg != [] }
  $command = join($_command, ' ')

  cron { 'letsencrypt-renew':
    ensure   => $cron_ensure,
    command  => $command,
    user     => 'root',
    hour     => $cron_hour,
    minute   => $cron_minute,
    monthday => $cron_monthday,
  }
}
