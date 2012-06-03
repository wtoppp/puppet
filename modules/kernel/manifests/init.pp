class kernel::parameter {
  augeas {"kerneladjust":
     context => "/files/etc/sysctl.conf",
     changes => [
            "set net.ipv4.tcp_syncookies 1",
	    "set net.ipv4.tcp_syn_retries 4",
	    "set net.ipv4.tcp_synack_retries 4",
	    "set net.ipv4.tcp_retries2 10"
	    ],
  }
}
