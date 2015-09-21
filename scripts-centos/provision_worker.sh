#!/bin/bash

# stop iptables
service iptables save
service iptables stop
chkconfig iptables off

# update the vagrant user password otherwise ssh does not work
echo vagrant | passwd vagrant --stdin

# start ntp server
/etc/init.d/ntpd start
chkconfig --add ntpd
chkconfig ntpd on