# Class: play
#
# This module manages play framework applications and modules.
# The class itself installs Play 2.2.0 in /usr/local/share/applications/play-2.2.0
#
# Actions:
#  play::module checks the availability of a Play module. It installs
#  it if not found
#  play::application starts a play application
#  play::service starts a play application as a system service
#
# Parameters:
# *version* : the Play version to install
#
# Requires:
# wget puppet module https://github.com/EslamElHusseiny/puppet-wget
# A proper java installation and JAVA_HOME set
# Sample Usage:
#  include play
#  play::module {"mongodb module" :
# 	module  => "mongo-2.4.6", 
#	require => [Class["play"], Class["mongodb"]]
#  }
#
#  play::module { "less module" :
# 	module  => "less-0.3",
#	require => Class["play"]
#  }
#
#  play::service { "bilderverwaltung" :
#	path    => "/home/clement/demo/bilderverwaltung",
#	require => [Jdk7["Java7SDK"], Play::Module["mongodb module"]]
#  }
#
class play ($version = "2.2.0", $install_path = "/usr/local/share/applications/play-2.2.0") {

	include wget

	$play_version = $version
	$play_path = "${install_path}/play-${play_version}"
	$download_url = $play_version ? {
	  default => "http://downloads.typesafe.com/play/${play_version}/play-${play_version}.zip"
	}
	
	notice("Installing Play ${play_version}")
        wget::fetch {'download-play-framework':
          source      => "$download_url",
          destination => "/tmp/play-${play_version}.zip",
          timeout     => 0,
        }

    exec { "mkdir.play.install.path":
        command => "/bin/mkdir -p ${install_path}"
    }
    ->
    exec {"unzip-play-framework":
      cwd     => "${install_path}",
      command => "/usr/bin/unzip -u -o /tmp/play-${play_version}.zip",
      require => [ Package["unzip"], Wget::Fetch["download-play-framework"], Exec["mkdir.play.install.path"] ],
    }
    ->
    file { "$play_path/play":
      ensure  => file,
      owner   => "root",
      mode    => "0755",
      require => [Exec["unzip-play-framework"]]
    }
    ->
    file {'/usr/bin/play':
      ensure  => 'link',
      target  => "$play_path/play",
      require => File["$play_path/play"],
    }
    ->
    # Add a unversioned symlink to the play installation.
    file { "${install_path}/play":
        ensure => link,
        target => $play_path,
        require => Exec["mkdir.play.install.path", "unzip-play-framework"]
    }
    if !defined(Package['unzip']){ package{"unzip": ensure => installed} }	
}
