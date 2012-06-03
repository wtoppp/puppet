class en_cron{

$vim_pkg=$operatingsystem? {
       CentOS => "vim-enhanced",
       default => "vim-minimal"
}
package {"$vim_pkg":
         ensure => "present"
        }
package {"cronie":
         ensure => "present",
         before => Cron["NTPtime"],
        }
package {"ntpdate":
        ensure => installed,
        before => Cron["NTPtime"],
      }
cron {"NTPtime":
      ensure => present,
      command => "/usr/sbin/ntpdate 0.rhel.pool.ntp.org",
      user => "root",
      hour => ['2-23'],
      minute => "*/1",
      require => [ Package["cronie"],Package["ntpdate"] ],
    }
}
###############
class en_file{
file { "/root/scripts":
        ensure => directory
     }
file {"/root/scripts/check_inode.sh":
      ensure => "file",
      source => "puppet://$server/flist/check_inode.sh",
      mode => 755,
      require => File["/root/scripts"]
     }
}

