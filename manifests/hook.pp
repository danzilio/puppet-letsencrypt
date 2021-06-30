# @summary Creates hook scripts.
#
# This type is used by letsencrypt::renew and letsencrypt::certonly to create hook scripts.
#
# @param type Hook type.
# @param hook_file Path to deploy hook script.
# @param commands Bash commands to execute when the hook is run by certbot.
# @param hook_file_group Group owner of the hook file
#
define letsencrypt::hook (
  Enum['pre', 'post', 'deploy'] $type,
  # hook.sh.epp will validate this
  Variant[String[1],Array[String[1]]] $commands,
  String[1]                     $hook_file,
  String[1]                     $hook_file_group = $letsencrypt::root_file_owner_group,
) {
  $validate_env = $type ? {
    'deploy' => true,
    default  => false,
  }

  file { $hook_file:
    ensure  => file,
    owner   => 'root',
    group   => $hook_file_group,
    mode    => '0755',
    content => epp('letsencrypt/hook.sh.epp', {
        commands     => $commands,
        validate_env => $validate_env,
    }),
    # Defined in letsencrypt::config
    require => File['letsencrypt-renewal-hooks-puppet'],
  }
}
