#!/bin/bash
yum install curl -y
REPOCM=${REPOCM:-cm5}
CM_REPO_HOST=${CM_REPO_HOST:-archive.cloudera.com}
CM_MAJOR_VERSION=$(echo $REPOCM | sed -e 's/cm\([0-9]\).*/\1/')
CM_VERSION=$(echo $REPOCM | sed -e 's/cm\([0-9][0-9]*\)/\1/')
OS_DISTID="redhat"
OS_VERSION=$(cat /etc/redhat-release | awk '{print $3}' | sed 's/\..//')
OS_ARCH=$(arch)

# Setup the Cloudera repo
cat > /etc/yum.repos.d/cloudera-$REPOCM.repo <<EOF
[cloudera-manager]
# Packages for Cloudera Manager, Version 5, on RedHat or CentOS 6 x86_64
name=Cloudera Manager
baseurl=http://$CM_REPO_HOST/cm$CM_MAJOR_VERSION/$OS_DISTID/$OS_VERSION/$OS_ARCH/cm/$CM_MAJOR_VERSION/
gpgkey = http://$CM_REPO_HOST/cm$CM_MAJOR_VERSION/$OS_DISTID/$OS_VERSION/$OS_ARCH/cm/RPM-GPG-KEY-cloudera
gpgcheck = 1
EOF

# Import keys, install packagesm start services
export DEBIAN_FRONTEND=noninteractive
rpm --import http://$CM_REPO_HOST/cm$CM_MAJOR_VERSION/$OS_DISTID/$OS_VERSION/$OS_ARCH/cm/RPM-GPG-KEY-cloudera
yum install -y oracle-j2sdk1.7 cloudera-manager-server-db-2 cloudera-manager-server cloudera-manager-daemons

# stop iptables
service iptables save
service iptables stop
chkconfig iptables off

service cloudera-scm-server-db initdb
service cloudera-scm-server-db start
service cloudera-scm-server start

# update the vagrant user password otherwise ssh does not work
echo vagrant | passwd vagrant --stdin

# start ntp server
/etc/init.d/ntpd start
chkconfig --add ntpd
chkconfig ntpd on

# add dns addresses
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
echo 'nameserver 8.8.4.4' >> /etc/resolv.conf

