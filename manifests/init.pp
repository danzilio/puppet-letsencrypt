# @summary Install and configure Certbot, the LetsEncrypt client
#
# Install and configure Certbot, the LetsEncrypt client
#
# @example
#  class { 'letsencrypt' :
#    email  => 'letsregister@example.com',
#    config => {
#      'server' => 'https://acme-staging-v02.api.letsencrypt.org/directory',
#    },
#  }
#
# @param email
#   The email address to use to register with Let's Encrypt. This takes
#   precedence over an 'email' setting defined in $config.
# @param environment An optional array of environment variables
# @param package_name Name of package and command to use when installing the client with the `package` method.
# @param package_ensure The value passed to `ensure` when installing the client with the `package` method.
# @param package_command Path or name for letsencrypt executable when installing the client with the `package` method.
# @param config_file The path to the configuration file for the letsencrypt cli.
# @param config A hash representation of the letsencrypt configuration file.
# @param cron_scripts_path The path for renewal scripts called by cron
# @param cron_owner_group Group owner of cron renew scripts.
# @param root_file_owner_group Group owner for the shipped files
# @param manage_config A feature flag to toggle the management of the letsencrypt configuration file.
# @param manage_install A feature flag to toggle the management of the letsencrypt client installation.
# @param manage_dependencies A feature flag to toggle the management of the letsencrypt dependencies.
# @param configure_epel A feature flag to include the 'epel' class and depend on it for package installation.
# @param agree_tos A flag to agree to the Let's Encrypt Terms of Service.
# @param unsafe_registration A flag to allow using the 'register-unsafely-without-email' flag.
# @param config_dir The path to the configuration directory.
# @param key_size Size for the RSA public key
# @param renew_pre_hook_commands Array of commands to run in a shell before obtaining/renewing any certificates.
# @param renew_post_hook_commands Array of commands to run in a shell after attempting to obtain/renew certificates.
# @param renew_deploy_hook_commands
#   Array of commands to run in a shell once for each successfully issued/renewed
#   certificate. Two environmental variables are supplied by certbot:
#   - $RENEWED_LINEAGE: Points to the live directory with the cert files and key.
#                       Example: /etc/letsencrypt/live/example.com
#   - $RENEWED_DOMAINS: A space-delimited list of renewed certificate domains.
#                       Example: "example.com www.example.com"
# @param renew_additional_args Array of additional command line arguments to pass to 'certbot renew'.
# @param renew_cron_ensure Intended state of the cron resource running certbot renew.
# @param renew_cron_hour
#   Optional string, integer or array of hour(s) the renewal command should run.
#   E.g. '[0,12]' to execute at midnight and midday.
#   hour.
# @param renew_cron_minute
#   Optional string, integer or array of minute(s) the renewal command should
#   run. E.g. 0 or '00' or [0,30].
# @param renew_cron_monthday
#   Optional string, integer or array of monthday(s) the renewal command should
#   run. E.g. '2-30/2' to run on even days.
#
class letsencrypt (
  Boolean $configure_epel,
  Optional[String] $email                = undef,
  Array $environment                     = [],
  String $package_name                   = 'certbot',
  $package_ensure                        = 'installed',
  String $package_command                = 'certbot',
  Stdlib::Unixpath $config_dir           = '/etc/letsencrypt',
  String $config_file                    = "${config_dir}/cli.ini",
  Hash $config                           = { 'server' => 'https://acme-v02.api.letsencrypt.org/directory' },
  String $cron_scripts_path              = "${facts['puppet_vardir']}/letsencrypt",
  String $cron_owner_group               = 'root',
  String $root_file_owner_group          = 'root',
  Boolean $manage_config                 = true,
  Boolean $manage_install                = true,
  Boolean $manage_dependencies           = true,
  Boolean $agree_tos                     = true,
  Boolean $unsafe_registration           = false,
  Integer[2048] $key_size                = 4096,
  # $renew_* should only be used in letsencrypt::renew (blame rspec)
  $renew_pre_hook_commands               = [],
  $renew_post_hook_commands              = [],
  $renew_deploy_hook_commands            = [],
  $renew_additional_args                 = [],
  $renew_cron_ensure                     = 'absent',
  $renew_cron_hour                       = fqdn_rand(24),
  $renew_cron_minute                     = fqdn_rand(60, fqdn_rand_string(10)),
  $renew_cron_monthday                   = '*',
) {
  if $manage_install {
    contain letsencrypt::install # lint:ignore:relative_classname_inclusion
    Class['letsencrypt::install'] ~> Exec['initialize letsencrypt']
    Class['letsencrypt::install'] -> Class['letsencrypt::renew']
  }

  $command = $package_command

  if $manage_config {
    contain letsencrypt::config # lint:ignore:relative_classname_inclusion
    Class['letsencrypt::config'] -> Exec['initialize letsencrypt']
  }

  contain letsencrypt::renew

  # TODO: do we need this command when installing from package?
  exec { 'initialize letsencrypt':
    command     => "${package_command} -h",
    path        => $facts['path'],
    environment => $environment,
    refreshonly => true,
  }

  # Used in letsencrypt::certonly Exec["letsencrypt certonly ${title}"]
  file { '/usr/local/sbin/letsencrypt-domain-validation':
    ensure => file,
    owner  => 'root',
    group  => $root_file_owner_group,
    mode   => '0500',
    source => "puppet:///modules/${module_name}/domain-validation.sh",
  }
}
