#!bin/bash
function installAssembly() {
    kubeVersion=$1

    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=CentOS-$releasever - Kubernetes - mirrors.aliyun.com
failovermethod=priority
baseurl=http://10.75.8.152:1111/kubernetes/
gpgcheck=0
EOF

    cat <<EOF > /etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=CentOS-$releasever - Docker CE - mirrors.aliyun.com
failovermethod=priority
baseurl=http://10.75.8.152:1111/docker-ce-stable/
gpgcheck=0
EOF

    yum clean all
    yum makecache
    yum install -y ipset vim ipvsadm wget device-mapper-persistent-data lvm2
    yum install -y kubelet-${kubeVersion} kubeadm-${kubeVersion} kubectl-${kubeVersion} containerd.io cri-tools
    systemctl enable kubelet
    systemctl enable containerd
}
