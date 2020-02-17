---
title: Ceph集群安装
date: 2020-02-14 10:28:30
tags:
  - Ceph 
  - 运维
  - 分布式存储
---
# CephFS集群安装

### 一、集群规划

节点 | ip | os | 节点说明
- | - | - | -
master1 | 10.73.13.61 | centos7.4 | mon+rgw+manger节点、ceph-deploy
master2 | 10.73.13.60 | centos7.4 | mon+rgw+manger节点
master3 | 10.73.13.59 | centos7.4 | mon+rgw+manger节点

### 二、安装ceph-deploy

1. Install and enable the Extra Packages for Enterprise Linux (EPEL) repository:Install and enable the Extra Packages for Enterprise Linux (EPEL) repository:

```sh
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```

2. 添加ceph仓库（阿里源，同时在所有节点进行如下操作）

```sh
cat << EOM > /etc/yum.repos.d/ceph.repo
[Ceph]
name=Ceph packages for $basearch
baseurl=https://mirrors.aliyun.com/ceph/rpm-mimic/el7/$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
priority=1

[Ceph-noarch]
name=Ceph noarch packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-mimic/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
priority=1

[ceph-source]
name=Ceph source packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-mimic/el7/SRPMS
enabled=1
EOM
```
3. 安装python-setuptools、ceph-deploy

```sh
sudo yum install python-setuptools
sudo yum install ceph-deploy
```

### 三、节点准备

以下操作需在所有节点进行。

1. 免密登录

```sh
# 1、三次回车后，密钥生成完成
ssh-keygen
# 2、拷贝密钥到其他节点
ssh-copy-id -i ~/.ssh/id_rsa.pub  用户名字@192.168.x.xxx
```

2. 时间同步

网上教程很多，具体可参考网上文档。
```sh
sudo yum install ntpdate
ntpdate -u ntp.api.bz
```

3. 关闭SELinux、防火墙

```sh
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
```

4. 关闭系统的Swap（Kubernetes 1.8开始要求）
	
```sh
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab
```

### 四、集群安装

以下操作在ceph-deploy节点。

1. 创建集群

```sh
mkdir /etc/ceph && cd /etc/ceph
# ceph-deploy new {initial-monitor-node(s)}
ceph-deploy new master1 master2 master3 
```

2. 设置集群配置

* 具体集群配置说明，待后续更新

```sh
cat /etc/ceph/ceph.conf
[global]
public_network = 10.73.13.0/16
cluster_network = 10.73.13.0/16

fsid = 464c2aa2-7426-4d6b-a0ae-961d1589ee53
mon_initial_members = master1, master2, master3
mon_host = 10.73.13.61,10.73.13.60,10.73.13.59
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx

osd_pool_default_size = 3
osd_pool_default_min_size = 1
osd_pool_default_pg_num = 8
osd_pool_default_pgp_num = 8
osd_crush_chooseleaf_type = 1

[mon]
mon_clock_drift_allowed = 0.5
mon allow pool delete = true

[osd]
osd_mkfs_type = xfs
osd_mkfs_options_xfs = -f
filestore_max_sync_interval = 5
filestore_min_sync_interval = 0.1
filestore_fd_cache_size = 655350
filestore_omap_header_cache_size = 655350
filestore_fd_cache_random = true
osd op threads = 8
osd disk threads = 4
filestore op threads = 8
max_open_files = 655350

[mgr]
mgr modules = dashboard

```

3. 为所有节点安装ceph

```sh
# ceph-deploy install {initial-monitor-node(s)} --no-adjust-repos
# --no-adjust-repos参数的意思是不更新节点配置的ceph源，因为在安装ceph-deploy的步骤下已经为节点配置了阿里云的ceph源
ceph-deploy new master1 master2 master3 --no-adjust-repos
```

4. 初始化节点配置,生产相应的keys

```sh
ceph-deploy mon create-initial
```

完成之后会在/etc/ceph目录下生成以下几个文件

```sh
ceph.client.admin.keyring
ceph.bootstrap-mgr.keyring
ceph.bootstrap-osd.keyring
ceph.bootstrap-mds.keyring
ceph.bootstrap-rgw.keyring
ceph.bootstrap-rbd.keyring
ceph.bootstrap-rbd-mirror.keyring
```

5. 拷贝文件至部署节点

```sh
ceph-deploy admin master1 master2 master3
```

6. 部署mgr

```sh
ceph-deploy mgr create master1 master2 master3
```

7. 添加OSD

```sh
ceph-deploy osd create --data /dev/vdb master1
ceph-deploy osd create --data /dev/vdb master2
ceph-deploy osd create --data /dev/vdb master3
```

### 五、创建CephFS文件系统

1. 部署metadata服务

```sh
ceph-deploy mds create master1 master2 master3
```

2. 生成CephFS

```sh
ceph osd pool create cephfs_data 128
ceph osd pool create cephfs_meta 128
ceph fs new mycephfs cephfs_meta cephfs_data
```
