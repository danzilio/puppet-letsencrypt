# @summary Installs and configures the dns-cloudflare plugin
#
# This class installs and configures the Let's Encrypt dns-cloudflare plugin.
# https://certbot-dns-cloudflare.readthedocs.io
#
# @param package_name The name of the package to install when $manage_package is true.
# @param api_key
#   Optional string, cloudflare api key value for authentication.
# @param api_token
#   Optional string, cloudflare api token value for authentication.
# @param email
#   Optional string, cloudflare account email address, used in conjunction with api_key.
# @param config_dir The path to the configuration directory.
# @param manage_package Manage the plugin package.
# @param propagation_seconds Number of seconds to wait for the DNS server to propagate the DNS-01 challenge.
#
class letsencrypt::plugin::dns_cloudflare (
  Optional[String[1]] $package_name = undef,
  Optional[String[1]] $api_key      = undef,
  Optional[String[1]] $api_token    = undef,
  Optional[String[1]] $email        = undef,
  Stdlib::Absolutepath $config_path = "${letsencrypt::config_dir}/dns-cloudflare.ini",
  Boolean $manage_package           = true,
  Integer $propagation_seconds      = 10,
) {
  require letsencrypt

  if ! $api_key and ! $api_token {
    fail('No authentication method provided, please specify either api_token or api_key and api_email.')
  }

  if $manage_package {
    if ! $package_name {
      fail('No package name provided for certbot dns cloudflare plugin.')
    }

    package { $package_name:
      ensure => installed,
    }
  }

  if $api_token {
    $ini_vars = {
      dns_cloudflare_api_token => $api_token,
    }
  }
  else {
    if ! $email {
      fail('Cloudflare email not provided for specified api_key.')
    }

    $ini_vars = {
      dns_cloudflare_api_key => $api_key,
      dns_cloudflare_email   => $email,
    }
  }

  file { $config_path:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0400',
    content => epp('letsencrypt/ini.epp', {
        vars => { '' => $ini_vars },
    }),
  }
}
