class centos6yum {

case $operatingsystem {
   "CentOS": {
        case $architecture {
	  "i386": { 
               yumrepo { "163yumrepoi386":
                  descr => "this is 163 yum repo For i386",
                  baseurl => "http://mirrors.163.com/centos/6/os/i386/",
                  gpgcheck => "0",
                  enabled => "0";
               }
	    }
	 "x86_64": {
	       yumrepo { "163yumrepox86_64":
                  descr => "this is 163 yum repo For x86_64",
                  baseurl => "http://mirrors.163.com/centos/6/os/x86_64/",
                  gpgcheck => "0",
                  enabled => "0";
               }
	   }
        }
     }
  }
}
