# @summary Installs the Let's Encrypt client.
#
# @param manage_install A feature flag to toggle the management of the letsencrypt client installation.
# @param manage_dependencies  A feature flag to toggle the management of the letsencrypt dependencies.
# @param configure_epel  A feature flag to include the 'epel' class and depend on it for package installation.
# @param install_method Method to install the letsencrypt client
# @param path The path to the letsencrypt installation.
# @param repo A Git URL to install the Let's encrypt client from.
# @param version The Git ref (tag, sha, branch) to check out when installing the client with the `vcs` method.
# @param vcs_dependencies Array of packages to install before executing vcs installation.
# @param package_ensure The value passed to `ensure` when installing the client with the `package` method.
# @param package_name Name of package to use when installing the client with the `package` method.
#
class letsencrypt::install (
  Boolean $manage_install                = $letsencrypt::manage_install,
  Boolean $manage_dependencies           = $letsencrypt::manage_dependencies,
  Boolean $configure_epel                = $letsencrypt::configure_epel,
  Enum['package', 'vcs'] $install_method = $letsencrypt::install_method,
  String $package_name                   = $letsencrypt::package_name,
  String $package_ensure                 = $letsencrypt::package_ensure,
  String $path                           = $letsencrypt::path,
  String $repo                           = $letsencrypt::repo,
  String $version                        = $letsencrypt::version,
  Array[String[1]] $vcs_dependencies     = $letsencrypt::vcs_dependencies,
) {
  if $install_method == 'vcs' {
    if $manage_dependencies {
      ensure_packages($vcs_dependencies)
      Package[$vcs_dependencies] -> Vcsrepo[$path]
    }

    vcsrepo { $path:
      ensure   => present,
      provider => git,
      source   => $repo,
      revision => $version,
    }
  } else {
    package { 'letsencrypt':
      ensure => $package_ensure,
      name   => $package_name,
    }

    if $configure_epel {
      include epel
      Class['epel'] -> Package['letsencrypt']
    }
  }
}
