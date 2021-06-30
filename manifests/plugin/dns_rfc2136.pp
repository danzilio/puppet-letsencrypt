# @summary Installs and configures the dns-rfc2136 plugin
#
# This class installs and configures the Let's Encrypt dns-rfc2136 plugin.
# https://certbot-dns-rfc2136.readthedocs.io
#
# @param server Target DNS server.
# @param key_name TSIG key name.
# @param key_secret TSIG key secret.
# @param key_algorithm TSIG key algorithm.
# @param port Target DNS port.
# @param propagation_seconds Number of seconds to wait for the DNS server to propagate the DNS-01 challenge.
# @param manage_package Manage the plugin package.
# @param package_name The name of the package to install when $manage_package is true.
# @param config_dir The path to the configuration directory.
# @param ini_file_owner_group Group owner of the generated ini file
#
class letsencrypt::plugin::dns_rfc2136 (
  Stdlib::Host $server,
  String[1] $key_name,
  String[1] $key_secret,
  String[1] $package_name,
  String[1] $key_algorithm         = 'HMAC-SHA512',
  Stdlib::Port $port               = 53,
  Integer $propagation_seconds     = 10,
  Stdlib::Absolutepath $config_dir = $letsencrypt::config_dir,
  Boolean $manage_package          = true,
  String $ini_file_owner_group     = $letsencrypt::root_file_owner_group,
) {
  require letsencrypt

  if $manage_package {
    package { $package_name:
      ensure => installed,
    }
  }

  $ini_vars = {
    dns_rfc2136_server    => $server,
    dns_rfc2136_port      => $port,
    dns_rfc2136_name      => $key_name,
    dns_rfc2136_secret    => $key_secret,
    dns_rfc2136_algorithm => $key_algorithm,
  }

  file { "${config_dir}/dns-rfc2136.ini":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => epp('letsencrypt/ini.epp', {
        vars => { '' => $ini_vars },
    }),
  }
}
