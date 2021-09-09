#!/usr/bin/env bash
# 获取硬盘名
DISK=$1
#DISKFULLPATH=$2
# 检查硬盘是否存在
CHECK_DISK_EXIST=`/sbin/fdisk -l 2> /dev/null | grep -o "$DISK"`
[ ! "$CHECK_DISK_EXIST" ] && { echo "Error: Disk is not found !"; exit 1;}
# 检查硬盘是否已存在分区
CHECK_DISK_PARTITION_EXIST=`/sbin/fdisk -l 2> /dev/null | grep -o "$DISK[1-9]"`
[ ! "$CHECK_DISK_PARTITION_EXIST" ] || { echo "WARNING: ${CHECK_DISK_PARTITION_EXIST} is Partition already !"; exit 1;}
# 开始格式化
/sbin/fdisk $DISK<<EOF &> /dev/null
n
p
1


t
8e
wq
EOF

# 创建物理卷
pvcreate $DISK"1"
# 新建卷组
vgcreate vgdata $DISK"1"
# 新建逻辑卷
lvcreate -l 100%FREE -n lvdata1 vgdata
# 格式化逻辑卷
#mkfs.xfs /dev/mapper/vgdata-lvdata1 
# 挂在卷组到 /data下
#mount /dev/mapper/vgdata-lvdata1 /data/
# 开启开机自启动
#echo `sudo blkid /dev/mapper/vgdata-lvdata1 | awk '{print $2}' | sed 's/\"//g'` /data xfs defaults 0 0 >> /etc/fstab

echo "Disk Partition Create OK!"

# 删除卷
#lvremove /dev/mapper/vgdata-lvdata1
#vgremove vgdata
#pvremove /dev/sdb1
#fdisk /dev/sdb（d）


#手动创建
#fdisk /dev/sdb
#pvcreate /dev/sdb1
#vgcreate vgdata /dev/sdb1
#lvcreate -l 100%FREE -n lvdata1 vgdata
#mkfs.xfs /dev/mapper/vgdata-lvdata1
#mount /dev/mapper/vgdata-lvdata1 /data/