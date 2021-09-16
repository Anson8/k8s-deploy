#!/bin/bash
#yum -y install wget
#wget https://elrepo.org/linux/kernel/el7/x86_64/RPMS/kernel-lt-5.4.144-1.el7.elrepo.x86_64.rpm -P /opt/kubernetes/
rpm -ivh /opt/kubernetes/kernel-lt-5.4.144-1.el7.elrepo.x86_64.rpm
A=`sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg |grep "(5.4.144-1.el7.elrepo.x86_64) 7 (Core)" |awk '{print $1}'`
grub2-set-default $A
reboot