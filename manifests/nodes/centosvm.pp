define check_process() {
  exec { "is-process-${name}-running?":
      command => "/bin/ps ax |/bin/grep -v 'grep'|/bin/grep ${name} >/tmp/pslist.${name}.txt",
      logoutput => on_failure,
  }
}
node "centosvm" {
include centos6yum
include en_cron
/* kernel::parameter class coming from modules/kernel loading automaticaly by system */
include kernel::parameter

/* define like class ,it can use some variable in it */
check_process { "gmond": }

}
