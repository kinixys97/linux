#!/bin/bash
echo
echo "###################################"
echo "### CentOS7 Configuration Start ###"
echo "###################################"
echo

# 사용자 입력
read -p "Enter the hostname: " hostname
read -p "Enter the IP address for em1: " ip_em1
read -p "Enter the netmask for em1: " netmask_em1
read -p "Enter the gateway for em1: " gateway_em1
read -p "Enter the IP address for em2: " ip_em2
read -p "Enter the netmask for em2: " netmask_em2
echo

echo "### 1/9: SELINUX Start ###"
# SELINUX Configuration
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0
echo "### 1/9: SELINUX Finish ###"
echo
echo

echo "### 2/9: Hostname Start ###"
# Hostname setting
hostnamectl set-hostname "${hostname}" --static 
echo "### 2/9: Hostname Finish ###"
echo
echo

echo "### 3/9: Firewalld Start ###"
# Firewall Disabled
systemctl disable firewalld
systemctl stop firewalld
echo "### 3/9: Firewalld Finish ###"
echo
echo

echo "### 4/9: Network Start ###"
# Network Configuration
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-em1
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/g' /etc/sysconfig/network-scripts/ifcfg-em1
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-em2
sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/g' /etc/sysconfig/network-scripts/ifcfg-em2

if ! grep -q "IPADDR=" /etc/sysconfig/network-scripts/ifcfg-em1; then
    echo IPADDR="${ip_em1}" >> /etc/sysconfig/network-scripts/ifcfg-em1
fi

if ! grep -q "NETMASK=" /etc/sysconfig/network-scripts/ifcfg-em1; then
    echo NETMASK="${netmask_em1}" >> /etc/sysconfig/network-scripts/ifcfg-em1
fi

if ! grep -q "GATEWAY=" /etc/sysconfig/network-scripts/ifcfg-em1; then
    echo GATEWAY="${gateway_em1}" >> /etc/sysconfig/network-scripts/ifcfg-em1
fi

if ! grep -q "IPADDR=" /etc/sysconfig/network-scripts/ifcfg-em2; then
    echo IPADDR="${ip_em2}" >> /etc/sysconfig/network-scripts/ifcfg-em2
fi

if ! grep -q "NETMASK=" /etc/sysconfig/network-scripts/ifcfg-em2; then
    echo NETMASK="${netmask_em2}" >> /etc/sysconfig/network-scripts/ifcfg-em2
fi

echo nameserver 8.8.8.8 > /etc/resolv.conf
systemctl restart NetworkManager
echo "### 4/9: Network Finish ###"
echo
echo

echo "### 5/9: SSH Start ###"
# SSH Configuration
sed -i 's/#Port 22/Port 9022/g' /etc/ssh/sshd_config
systemctl restart sshd
echo "### 5/9: SSH Finish ###"
echo
echo

echo "### 6/9: iptables Start ###"
# iptables Configuration
iptables -F
iptables -A INPUT -p tcp --dport 9022 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
echo "### 6/9: iptables Finish ###"
echo
echo

echo "### 7/9: Fdisk Start ###"
# fdisk /dev/sdb Configuration
DISK="/dev/sdb"  
PARTITION="${DISK}1"

(
echo n      
echo p      
echo 1      
echo        
echo        
echo w     
) | fdisk $DISK

mkfs.ext4 $PARTITION
echo "### 7/9: Fdisk Finish ###"
echo
echo

echo "### 8/9: Disk Mount Start ###"
NEWDISK=$(blkid | grep 'dev/sdb1' | awk -F '"' '{print $2}')

if [ ! -d "/data" ]; then
  mkdir /data
else
  echo "/data directory already exists."
fi

echo UUID=${NEWDISK} /data                   ext4     defaults        1 2 >> /etc/fstab
mount -a 
echo "### 8/9: Disk Mount Finish ###"
echo
echo

echo "### 9/9: Zabbix Install Start ###"
curl -O  http://turtle.page.place/zabbix7.rpm  
rpm -ivh zabbix7.rpm
sed -i 's/Server=127.0.0.1/Server=61.255.88.166/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/# ListenPort=10050/ListenPort=10055/g' /etc/zabbix/zabbix_agentd.conf
echo "### 9/9: Zabbix Install Finish ###"
echo
echo

echo "###################################"
echo "### CentOS7 Configuration Finish ###"
echo "###################################"

# Rebooting 
read -p "Do you want to reboot the system? (Y/N): " answer
case "${answer,,}" in
    y|yes)
        echo "Rebooting the system in 3 seconds..."
        sleep 3
        init 6
        ;;
    n|no)
        echo "Skipping reboot."
        ;;
    *)
        echo "Invalid input. Please enter Y or N."
        ;;
esac
