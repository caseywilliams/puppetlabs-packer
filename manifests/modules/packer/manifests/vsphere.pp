class packer::vsphere inherits packer::vsphere::params {

  include packer::vsphere::repos
  include packer::vsphere::networking
  include packer::vsphere::fw

  user { root:
    ensure   => present,
    password => "$qa_root_passwd"
  }

  case $::osfamily {
    redhat: {
      if $::operatingsystemrelease in ['24', '25', '26', '27'] {
        Package {
          provider => 'dnf',
        }

        file { '/etc/dhclient.conf':
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          source  => 'puppet:///modules/packer/vsphere/dhclient.conf',
        }
      }
    }
    debian: {
      if $::operatingsystemrelease in ['18.04'] {
        # Enable systemd service for vsphere bootstrap
        file { "/etc/systemd/system/multi-user.target.wants/${startup_file_source}":
          ensure => 'link',
          target => $startup_file,
        }
      }
    }
  }

  package { $ruby_package:
    ensure => present,
  }

  file { $bootstrap_file:
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    content => template("packer/vsphere/${bootstrap_file_source}"),
  }

  file { $startup_file:
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("packer/vsphere/${startup_file_source}"),
  }

  file { '/root/.ssh':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    ensure => directory,
  }

  file { '/root/.ssh/authorized_keys':
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/packer/vsphere/authorized_keys',
    require => File[ '/root/.ssh' ]
  }

}
