#!/bin/bash
#
#filename: /path/nagios/libexec/check_inode.sh
#joy.huang
#2012/05/09
#purpose: Monitor for server system inode free state
#Note: first make sure directory "/path/nagios/libexec/nagiostmpfile" is writealbe for nagios user.
#
#Filesystem            Inodes   IUsed   IFree IUse% Mounted on
#/dev/sda1            1310720   79514 1231206    7% /
#/dev/sdb             27525120   15778 27509342    1% /mnt
#/dev/sdf1            32768000   56251 32711749    1% /mnt/devicevm
#/dev/sdc             27525120      14 27525106    1% /splashtop
#none                  984005       1  984004    1% /dev/shm
# define Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

used_threshold=80

nagioslib_path="/mnt/devicevm/monitorsys/nagios/libexec"
tmpfile="$nagioslib_path/nagiostmpfile"
inodestate_file="$tmpfile/inodestate.log"

if [ ! -d $tmpfile ];then
   mkdir -p $tmpfile
fi
if [ -e $inodestate_file ];then
rm -f $inodestate_file
fi
#get current inode state on all partion ,then write reult to one file
function currentinode(){
echo -e "Filesystem Inodes IUsed IFree IUse% Mounted on\n">$inodestate_file
df -i>>$inodestate_file
while read inode
do
echo "$inode"
done <$inodestate_file
}

function inodeMonitor(){

#get max used node value in all partion
used_nodeval=`df -i|awk -F'%' '{print $1}'|awk 'NF >2'|awk '{print $NF}'|grep -v 'IUse'|sort -rn|head -1`
}

## call function
 inodeMonitor

##determine used inode value is heigher than setting
if [ `echo $used_threshold - $used_nodeval|bc -q|egrep "^-"` ];then
    currentinode
    exit $STATE_WARNING
else
   currentinode
   exit $STATE_OK
fi
