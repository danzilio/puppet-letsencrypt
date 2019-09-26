# @summary Default parameters
# @api private
class letsencrypt::params {
  $agree_tos           = true
  $unsafe_registration = false
  $manage_config       = true
  $manage_install      = true
  $manage_dependencies = true
  $package_ensure      = 'installed'
  $path                = '/opt/letsencrypt'
  $venv_path           = '/opt/letsencrypt/.venv' # virtualenv path for vcs-installed letsencrypt
  $repo                = 'https://github.com/certbot/certbot.git'
  $cron_scripts_path   = "${facts['puppet_vardir']}/letsencrypt" # path for renewal scripts called by cron
  $version             = 'v0.30.2'
  $config              = {
    'server' => 'https://acme-v01.api.letsencrypt.org/directory',
  }

  if $facts['osfamily'] == 'Debian' {
    $install_method = 'package'
    $package_name = 'certbot'
    $package_command = 'certbot'
    $config_dir = '/etc/letsencrypt'
    $dns_rfc2136_package_name = 'python3-certbot-dns-rfc2136'
    $nginx_package_name = undef
  } elsif $facts['osfamily'] == 'RedHat' {
    $install_method = 'package'
    $package_name = 'certbot'
    $package_command = 'certbot'
    $config_dir = '/etc/letsencrypt'
    if $facts['operatingsystemmajrelease'] == '7' {
      $dns_rfc2136_package_name = 'python2-certbot-dns-rfc2136'
      $nginx_package_name = 'python2-certbot-nginx'
    } else {
      $dns_rfc2136_package_name = 'python3-certbot-dns-rfc2136'
      $nginx_package_name = 'python3-certbot-nginx'
    }
  } elsif $facts['osfamily'] == 'Gentoo' {
    $install_method = 'package'
    $package_name = 'app-crypt/certbot'
    $package_command = 'certbot'
    $config_dir = '/etc/letsencrypt'
    $dns_rfc2136_package_name = undef
    $nginx_package_name = undef
  } elsif $facts['osfamily'] == 'OpenBSD' {
    $install_method = 'package'
    $package_name = 'certbot'
    $package_command = 'certbot'
    $config_dir = '/etc/letsencrypt'
    $dns_rfc2136_package_name = undef
    $nginx_package_name = undef
  } elsif $facts['osfamily'] == 'FreeBSD' {
    $install_method = 'package'
    $package_name = 'py27-certbot'
    $package_command = 'certbot'
    $config_dir = '/usr/local/etc/letsencrypt'
    $dns_rfc2136_package_name = undef
    $nginx_package_name = undef
  } else {
    $install_method = 'vcs'
    $package_name = 'letsencrypt'
    $package_command = 'letsencrypt'
    $config_dir = '/etc/letsencrypt'
    $dns_rfc2136_package_name = undef
    $nginx_package_name = undef
  }

  $config_file = "${config_dir}/cli.ini"

  $configure_epel = $facts['osfamily'] == 'RedHat' and $facts['os']['name'] != 'Fedora'

  $cron_owner_group = $facts['osfamily'] ? {
    'OpenBSD' =>  'wheel',
    'FreeBSD' =>  'wheel',
    default   =>  'root',
  }

  $renew_pre_hook_commands    = []
  $renew_post_hook_commands   = []
  $renew_deploy_hook_commands = []
  $renew_additional_args      = []
  $renew_cron_ensure          = 'absent'
  $renew_cron_hour            = fqdn_rand(24)
  $renew_cron_minute          = fqdn_rand(60, fqdn_rand_string(10))
  $renew_cron_monthday        = '*'

  $dns_rfc2136_manage_package      = true
  $dns_rfc2136_port                = 53
  $dns_rfc2136_algorithm           = 'HMAC-SHA512'
  $dns_rfc2136_propagation_seconds = 10

  $nginx_manage_package       = true
}
