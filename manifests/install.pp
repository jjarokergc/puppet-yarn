# @summary Install Yarn
#
# @api private
#
class yarn::install (
  Enum['present','absent'] $package_ensure = $yarn::package_ensure,
  String[1] $package_name = $yarn::package_name,
  Enum['nvm','npm', 'source', 'package'] $install_method = $yarn::install_method,
  Stdlib::Absolutepath $source_install_dir = $yarn::source_install_dir,
  Stdlib::Absolutepath $symbolic_link = $yarn::symbolic_link,
  String[1] $user = $yarn::user,
  Stdlib::HTTPUrl $source_url = $yarn::source_url,
) {
  assert_private()

  Exec {
    path   => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  $install_dir = "${source_install_dir}/yarn"

  case $install_method {
    'source': {
      if ($package_ensure == 'absent') {
        file { $symbolic_link:
          ensure => 'absent',
        }

        -> file { $install_dir:
          ensure => 'absent',
          force  => true,
        }
      }
      else {
        ensure_packages(['wget', 'gzip', 'tar'])

        file { $install_dir:
          ensure => 'directory',
          owner  => $user,
        }

        -> exec { "wget ${source_url}":
          command => "wget ${source_url} -O yarn.tar.gz",
          cwd     => $install_dir,
          user    => $user,
          creates => "${install_dir}/yarn.tar.gz",
          require => Package['wget'],
        }

        -> exec { 'tar zvxf yarn.tar.gz':
          command => 'tar zvxf yarn.tar.gz',
          cwd     => $install_dir,
          user    => $user,
          creates => "${install_dir}/dist",
          require => Package['gzip', 'tar'],
        }

        -> file { $symbolic_link:
          ensure => 'link',
          owner  => $user,
          target => '/opt/yarn/dist/bin/yarn',
        }
      }
    }

    'npm': {
      if ($package_ensure == 'absent') {
        exec { "npm uninstall -g ${package_name}":
          user     => $user,
          command  => "npm uninstall -g ${package_name}",
          onlyif   => "npm list -depth 0 -g ${package_name}",
          provider => shell,
        }
      }
      else {
        exec { "npm install -g ${package_name}":
          user     => $user,
          command  => "npm install -g ${package_name}",
          unless   => "npm list -depth 0 -g ${package_name}",
          provider => shell,
        }
      }
    }

    'nvm': {
      if ($user == 'root') {
        fail("YARN INSTALLATION VIA NVM is meant for non-root user accounts; specify a non-root 'user'")
      }
      # Process Package
      if ($package_ensure == 'absent') {
        fail('YARN ABSENT - This is not implemented')
      }

      # Load nvm and then install package.  NVM must be installed separately.
      $user_home = "/home/${user}"
      $nvm_dir = "${user_home}/.nvm"
      exec { 'YARN: install via nvm':
        user        => $user,
        cwd         => $user_home,
        command     => "bash -s npm install -g ${package_name}",
        unless      => "bash -s npm list -depth 0 -g ${package_name}",
        path        => ['/bin', '/usr/bin'],
        environment => [
          "NVM_DIR=${nvm_dir}",
          "HOME=${user_home}",
        ],
      }
    }

    default: {
      package { $package_name:
        ensure => $package_ensure,
      }
    }
  }
}
