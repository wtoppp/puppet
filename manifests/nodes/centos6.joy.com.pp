Exec { path => "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/nginx/sbin", }

class updatepassword {
 user {'joy':
   ensure           => 'present',
   home             => '/home/joy',
   password         => 'vT3gz67WuTI9I',
   password_max_age => '99999',
   password_min_age => '0',
   shell            => '/bin/bash',
 }
}

class nginxservice {
 file {"/usr/local/nginx/conf/nginx.conf":
   ensure => 'file',
   source => "puppet://$server/nginxclient/nginx.conf",
   group  => 'root',
   mode   => '644',
   owner  => 'root',
 }
# exec {"Nginxstart":
#   command => "/usr/local/nginx/sbin/Nginxadmin.sh start",
#   unless  => "netstat -lntp|grep nginx 2>/dev/null",
# }
# exec {"Nginxreload":
#   command     => "/usr/local/nginx/sbin/Nginxadmin.sh reload",
#   subscribe   => File["/usr/local/nginx/conf/nginx.conf"],
#   refreshonly => true,
# }
 service {"nginx":
   ensure => running,
   hasrestart => true,
   hasstatus => true,
   subscribe   => File["/usr/local/nginx/conf/nginx.conf"],
   path => "/etc/init.d/",
   provider => "init",
}

}
node "centos6.joy.com" {
include centos6yum
include varnish
include en_cron
include en_file
include updatepassword
include nginxservice

/* kernel::parameter class coming from modules/kernel loading automaticaly by system */
include kernel::parameter
}
