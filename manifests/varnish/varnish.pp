class varnish{

file {
"/root/scripts-run":
   ensure => 'directory',
   group  => 'root',
   mode   => '755',
   owner  => 'root';

"varnish.vcl":
   name => '/root/scripts-run/varnish.vcl',
   ensure => 'file',
   source => "puppet://$server/varnish/default.vcl",
   group  => 'root',
   mode   => '644',
   owner  => 'root';
 } 

}
