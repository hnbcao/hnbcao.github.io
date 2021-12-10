---
title: Kubernetes集群安装
weight: 31
date: 2019-12-31 16:16:02
top: false
cover: true
toc: true
categories: 运维
tags: 
  - Kubernetes 
  - 运维
  - 容器化
---
# Kubernetes集群搭建

* 1、本文基于[kubeadm HA master(v1.13.0)离线包 + 自动化脚本 + 常用插件 For Centos/Fedora](https://www.kubernetes.org.cn/4948.html)编写，修改了master之间的负载均衡方式为HAProxy+keeplived方式。
* 2、此离线教程必须保证目标安装环境与离线包下载环境一致，或者是考虑做yum镜像源。
* 3、关于keepalived+haproxy负载均衡，由于是在阿里云上搭建的，事实上是没有实现的，至于为何也成功部署了环境，其实是每台机器上keepalived都处于激活状态，对虚拟ip的访问都映射到了本机，本机又通过haproxy将请求负载到了api-server上。这是个神奇的事情，直到现在才搞清楚keepalived+haproxy的原理，如果是在阿里云上部署，这块建议使用阿里云的负载均衡功能。（keepalived+haproxy是为了实现api-server的负载均衡）
* 4、关于内核，实际上升不升级应该问题都不是很大，至少目前环境没出现过问题。
* 5、关于kubernetes版本，目前该教程能支持最新的v1.15.3版本的安装，注意修改版本号。

集群方案：

- 发行版：CentOS 7
- 容器运行时
- 内核： 4.18.12-1.el7.elrepo.x86_64
- 版本：Kubernetes: 1.14.0
- 网络方案: Calico
- kube-proxy mode: IPVS
- master高可用方案：HAProxy keepalived LVS
- DNS插件: CoreDNS
- metrics插件：metrics-server
- 界面：kubernetes-dashboard

## 一、环境概述

| Host Name | Role | IP |
| ------ | ------ | ------ |
| master1 | master1 | 192.168.56.103 |
| master2 | master2 | 192.168.56.104 |
| master3 | master3 | 192.168.56.105 |
| node1 | node1 | 192.168.56.106 |
| node2 | node2 | 192.168.56.107 |
| node3 | node3 | 192.168.56.108 |

## 二、离线仓库制作（可选）

具体制作方式见：[CentOS离线镜像仓库创建](https://hnbcao.vip/2021/02/24/centos-chi-xian-jing-xiang-cang-ku-chuang-jian/)

需要制作的离线仓库有：

1. base repo

```sh
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
```

1. docker repo

```sh
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://download.docker.com/linux/centos/$releasever/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-stable-debuginfo]
name=Docker CE Stable - Debuginfo $basearch
baseurl=https://download.docker.com/linux/centos/$releasever/debug-$basearch/stable
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-stable-source]
name=Docker CE Stable - Sources
baseurl=https://download.docker.com/linux/centos/$releasever/source/stable
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-test]
name=Docker CE Test - $basearch
baseurl=https://download.docker.com/linux/centos/$releasever/$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-test-debuginfo]
name=Docker CE Test - Debuginfo $basearch
baseurl=https://download.docker.com/linux/centos/$releasever/debug-$basearch/test
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-test-source]
name=Docker CE Test - Sources
baseurl=https://download.docker.com/linux/centos/$releasever/source/test
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-nightly]
name=Docker CE Nightly - $basearch
baseurl=https://download.docker.com/linux/centos/$releasever/$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-nightly-debuginfo]
name=Docker CE Nightly - Debuginfo $basearch
baseurl=https://download.docker.com/linux/centos/$releasever/debug-$basearch/nightly
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg

[docker-ce-nightly-source]
name=Docker CE Nightly - Sources
baseurl=https://download.docker.com/linux/centos/$releasever/source/nightly
enabled=0
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
```

2. kubernetes repo

```sh
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```



## 三、软件安装

```sh

# 安装ifconfig
yum install net-tools -y

# 时间同步
yum install -y ntpdate

# 安装docker（建议18.06.3.ce）

## 列出Docker版本
yum list docker-ce --showduplicates | sort -r
## 安装指定版本
sudo yum install docker-ce-<VERSION_STRING>
eg:sudo yum install docker-ce-18.06.3.ce

# 安装文件管理器，XShell可通过rz sz命令上传或者下载服务器文件
yum install lrzsz -y

# 安装keepalived、haproxy
yum install -y socat keepalived ipvsadm haproxy

# 安装kubernetes相关组件

# 建议指定各个软件的版本号，使用yum list 软件名（如kubelet） --showduplicates | sort -r列出版本号。
yum install -y kubelet kubeadm kubectl ebtables

# 其他软件安装
yum install wget

```

## 四、节点系统配置

* 关闭SELinux、防火墙

```sh
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
```

* 关闭系统的Swap（Kubernetes 1.8开始要求）
	
```sh
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab
```

* 配置L2网桥在转发包时会被iptables的FORWARD规则所过滤，该配置被CNI插件需要，更多信息请参考[Network Plugin Requirements](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#network-plugin-requirements)

```sh
echo """
vm.swappiness = 0
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
""" > /etc/sysctl.conf
sysctl -p
```

[centos7添加bridge-nf-call-ip6tables出现No such file or directory](https://www.cnblogs.com/zejin2008/p/7102485.html),简单来说就是执行一下 modprobe br_netfilter

* 同步时间

```sh
ntpdate -u ntp.api.bz
```

* 升级内核到最新（已准备内核离线安装包，可选）
	
[centos7 升级内核](https://www.aliyun.com/jiaocheng/130885.html)

[参考文章](https://www.kubernetes.org.cn/5163.html)

```sh
grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg
grubby --default-kernel
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"
```

* 重启系统，确认内核版本后，开启IPVS（如果未升级内核，去掉ip_vs_fo）

```sh
uname -a
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
 /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
 if [ $? -eq 0 ]; then
 /sbin/modprobe \${kernel_module}
 fi
done
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs
```
	
执行sysctl -p报错可执行modprobe br_netfilter，请参考[centos7添加bridge-nf-call-ip6tables出现No such file or directory
](https://www.cnblogs.com/zejin2008/p/7102485.html)

* 所有机器需要设定/etc/sysctl.d/k8s.conf的系统参数(可选)

```sh
# https://github.com/moby/moby/issues/31208 
# ipvsadm -l --timout
# 修复ipvs模式下长连接timeout问题 小于900即可
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.ip_forward = 1
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.netfilter.nf_conntrack_max = 2310720
fs.inotify.max_user_watches=89100
fs.may_detach_mounts = 1
fs.file-max = 52706963
fs.nr_open = 52706963
net.bridge.bridge-nf-call-arptables = 1
vm.swappiness = 0
vm.overcommit_memory=1
vm.panic_on_oom=0
EOF
sysctl --system
```

* 设置开机启动

```sh
# 启动docker
sed -i "13i ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT" /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl enable docker
systemctl start docker
# 设置kubelet开机启动
systemctl enable kubelet

systemctl enable keepalived
systemctl enable haproxy
```

* 设置免密登录

```sh
# 1、三次回车后，密钥生成完成
ssh-keygen
# 2、拷贝密钥到其他节点
ssh-copy-id -i ~/.ssh/id_rsa.pub  用户名字@192.168.x.xxx
```

**、 Kubernetes要求集群中所有机器具有不同的Mac地址、产品uuid、Hostname。

## 五、keepalived+haproxy配置

```sh
cd ~/
# 创建集群信息文件
echo """
CP0_IP=192.168.56.103
CP1_IP=192.168.56.103
CP2_IP=192.168.56.104
VIP=192.168.56.102
NET_IF=eth0
CIDR=10.244.0.0/16
""" > ./cluster-info
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hnbcao/kubeadm-ha-master/v1.14.0/keepalived-haproxy.sh)"
```

安装Keepalived、Haproxy

* 这是个错误的操作，并不需要在node部署keepalived+haproxy，如果node节点无法ping通虚拟IP（VIP），其原因是当前环境无法实现vip，具体原因由于能力有限，只能麻烦自己找找咯，方便分享的话不胜感激。

* 各个节点需要配置keepalived 和 haproxy

```sh
#/etc/haproxy/haproxy.cfg
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    mode                    tcp
    log                     global
    option                  tcplog
    option                  dontlognull
    option                  redispatch
    retries                 3
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout check           10s
    maxconn                 3000

listen stats
    mode   http
    bind :10086
    stats   enable
    stats   uri     /admin?stats
    stats   auth    admin:admin
    stats   admin   if TRUE
    
frontend  k8s_https *:8443
    mode      tcp
    maxconn      2000
    default_backend     https_sri
    
backend https_sri
    balance      roundrobin
    server master1-api ${MASTER1_IP}:6443  check inter 10000 fall 2 rise 2 weight 1
    server master2-api ${MASTER2_IP}:6443  check inter 10000 fall 2 rise 2 weight 1
    server master3-api ${MASTER3_IP}:6443  check inter 10000 fall 2 rise 2 weight 1
```

```sh
#/etc/keepalived/keepalived.conf 
global_defs {
    router_id LVS_DEVEL
}

vrrp_script check_haproxy {
    script /etc/keepalived/check_haproxy.sh
    interval 3
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 80
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass just0kk
    }
    virtual_ipaddress {
        ${VIP}/24
    }
    track_script {   
        check_haproxy
    }
}
```

```sh
/etc/keepalived/check_haproxy.sh

#!/bin/bash
A=`ps -C haproxy --no-header |wc -l`
if [ $A -eq 0 ];then
/etc/init.d/keepalived stop
fi
```

注意两个配置中的${MASTER1 _ IP}, ${MASTER2 _ IP}, ${MASTER3 _ IP}、${VIP}需要替换为自己集群相应的IP地址

* 重启keepalived和haproxy

```sh
systemctl stop keepalived
systemctl enable keepalived
systemctl start keepalived
systemctl stop haproxy
systemctl enable haproxy
systemctl start haproxy
```

## 六、部署HA Master

HA Master的部署过程已经自动化，请在master-1上执行如下命令，并注意修改IP;

脚本主要执行三步：

1)、重置kubelet设置

```sh
kubeadm reset -f
rm -rf /etc/kubernetes/pki/
```

2)、编写节点配置文件并初始化master1的kubelet

```sh
echo """
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: v1.14.0
controlPlaneEndpoint: "${VIP}:8443"
maxPods: 100
networkPlugin: cni
imageRepository: registry.aliyuncs.com/google_containers
apiServer:
  certSANs:
  - ${CP0_IP}
  - ${CP1_IP}
  - ${CP2_IP}
  - ${VIP}
networking:
  # This CIDR is a Calico default. Substitute or remove for your CNI provider.
  podSubnet: ${CIDR}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
""" > /etc/kubernetes/kubeadm-config.yaml
kubeadm init --config /etc/kubernetes/kubeadm-config.yaml
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf ${HOME}/.kube/config
```

* 关于默认网关问题，如果有多张网卡，需要先将默认网关切换到集群使用的那张网卡上，否则可能会出现etcd无法连接等问题。（应用我用的虚拟机，有一张网卡无法做到各个节点胡同；route查看当前网关信息，route del default删除默认网关，route add default enth0设置默认网关enth0为网卡名）

3)、拷贝相关证书到master2、master3

```sh
for index in 1 2; do
  ip=${IPS[${index}]}
  ssh $ip "mkdir -p /etc/kubernetes/pki/etcd; mkdir -p ~/.kube/"
  scp /etc/kubernetes/pki/ca.crt $ip:/etc/kubernetes/pki/ca.crt
  scp /etc/kubernetes/pki/ca.key $ip:/etc/kubernetes/pki/ca.key
  scp /etc/kubernetes/pki/sa.key $ip:/etc/kubernetes/pki/sa.key
  scp /etc/kubernetes/pki/sa.pub $ip:/etc/kubernetes/pki/sa.pub
  scp /etc/kubernetes/pki/front-proxy-ca.crt $ip:/etc/kubernetes/pki/front-proxy-ca.crt
  scp /etc/kubernetes/pki/front-proxy-ca.key $ip:/etc/kubernetes/pki/front-proxy-ca.key
  scp /etc/kubernetes/pki/etcd/ca.crt $ip:/etc/kubernetes/pki/etcd/ca.crt
  scp /etc/kubernetes/pki/etcd/ca.key $ip:/etc/kubernetes/pki/etcd/ca.key
  scp /etc/kubernetes/admin.conf $ip:/etc/kubernetes/admin.conf
  scp /etc/kubernetes/admin.conf $ip:~/.kube/config

  ssh ${ip} "${JOIN_CMD} --control-plane"
done
```

4)、master2、master3加入节点

```sh
JOIN_CMD=`kubeadm token create --print-join-command`
ssh ${ip} "${JOIN_CMD} --control-plane"
```

完整脚本：

```sh
# 部署HA master
 
bash -c "$(curl -fsSL https://raw.githubusercontent.com/hnbcao/kubeadm-ha-master/v1.14.0/kube-ha.sh)"
```

## 七、加入节点

* 节点加入命令获取

```sh
#master节点执行该命令，再在节点执行获取到的命令
kubeadm token create --print-join-command
```
## 八、结束安装

此时集群还需要安装网络组件，我选择了calico。具体安装方式可访问[calico官网](https://www.projectcalico.org/)，或者运行本仓库里面addons/calico下的配置。注意替换里面的镜像和Deployment里面的环境变量CALICO_IPV4POOL_CIDR为/etc/kubernetes/kubeadm-config.yaml里面networking.podSubnet的值。

文章只是在文章[kubeadm HA master(v1.13.0)离线包 + 自动化脚本 + 常用插件 For Centos/Fedora](https://www.kubernetes.org.cn/4948.html)的基础上，修改了master的HA方案。关于集群安装的详细步骤，建议访问[kubeadm HA master(v1.13.0)离线包 + 自动化脚本 + 常用插件 For Centos/Fedora](https://www.kubernetes.org.cn/4948.html)。

