#!/bin/bash

function initNodeEnviroment() {
    cat <<EOF >>  /etc/security/limits.conf
root        soft        nofile        1048576
root        hard        nofile        1048576
root        soft        stack         10240
EOF

    # 内核调整
    cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-arptables = 1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
net.core.somaxconn = 32768
vm.swappiness=0 # 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它 vm.overcommit_memory=1 # 不检查物理内存是否够用
vm.panic_on_oom=0 # 开启 OOM
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
net.ipv4.conf.all.rp_filter = 1
net.ipv4.neigh.default.gc_thresh1 = 80000
net.ipv4.neigh.default.gc_thresh2 = 90000
net.ipv4.neigh.default.gc_thresh3 = 100000
EOF

    sysctl -p /etc/sysctl.d/k8s.conf

    # kube-proxy开启ipvs的前置条件
    modprobe br_netfilter
    cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
modprobe br_netfilter
EOF
    chmod +x /etc/sysconfig/modules/ipvs.modules && /etc/sysconfig/modules/ipvs.modules

    lsmod | grep -e ip_vs -e nf_conntrack_ipv4
    cut -f1 -d " " /proc/modules | grep -e ip_vs -e nf_conntrack_ipv4
    lsmod | grep ip_vs

    # 关闭防火墙
    systemctl stop firewalld.service
    systemctl disable firewalld.service

    # 关闭selinux
    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
    grep --color=auto '^SELINUX' /etc/selinux/config

    # 关闭Swap
    swapoff -a
    sed -i 's/.*swap.*/#&/' /etc/fstab 
}