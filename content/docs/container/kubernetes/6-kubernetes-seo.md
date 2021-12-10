---
title: kubernetes集群运行问题记录
weight: 36
date: 2020-01-02 09:17:08
top: false
cover: true
toc: false
categories: 运维
tags:
- Kubernetes
- 运维
- 容器化
- Bugs
---
# kubernetes集群运行问题记录

- 集群内部容器无法解析外部DNS

  原因：由于节点名为nodex.domain.xx，集群内部容器的/etc/resolv.conf中search域会domain.xx域，容器在解析外网域名时默认会先在外网域名后添加.domain.xx进行域名解析，而外网存在域名domain.xx，且DNS解析域名为*.domain.xx，所以会将外网域名解析至*.domain.xx对应的IP地址，最终导致容器内部无法访问外网域名。

  解决办法：尽量避免集群内部节点名与外网域名冲突，可采用domain.local结尾等命名方式为节点命名。

- gitlab迁移之后系统异常

  原因：集群新建gitlab仓库各组件之间的认证文件与原有gialab不一致，导致恢复数据之后部分组件之间交互异常。

  解决办法：新建gitlab之前，迁移原有gitlab中所有的secret文件。

- kubernetes证书相关问题

  原因：由于没有配置etcd证书的sans，导致集群master节点故障时，etcd无法启动，集群崩溃。

  解决办法：

  1. 查看etcd日志，发现有出现关于证书的错误信息。master节点上执行``openssl x509 -text -in /etc/kubernetes/pki/etcd/server.crt -noout``查看证书的sans。输出证书信息为：

   ```shell
   Certificate:
   ...
           X509v3 extensions:
               ...
               X509v3 Subject Alternative Name: 
                   DNS:master1.segma.local, DNS:localhost, IP Address:192.168.1.202, IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1
   ...
   ```
  其中``X509v3 Subject Alternative Name``项中，DNS和IP地址不包括其他主节点地址，所以证书不完整，需要重新生成证书。

  2. 以下所有操作在所有主节点上执行。首先备份/etc/kubernetes/pki下所有文件
  
  ```shell
  cp -r /etc/kubernetes/pki /etc/kubernetes/pki_backup
  ```
  
  使用kubeadm生成证书，新建kubeadm config文件，填写其他master节点信息。内容如下：

  ```shell
  cat > etcd-cert-conf.yaml <<-EOF
  apiVersion: "kubeadm.k8s.io/v1beta2"
  kind: ClusterConfiguration
  kubernetesVersion: ${kubernetesVersion}
  etcd:
    local:
      serverCertSANs:
        - "master1.segma.local"
        - "master2.segma.local"
        - "master3.segma.local"
        - "192.168.1.202"
        - "192.168.1.151"
        - "192.168.1.130"
      peerCertSANs:
        - "master1.segma.local"
        - "master2.segma.local"
        - "master3.segma.local"
        - "192.168.1.202"
        - "192.168.1.151"
        - "192.168.1.130"
  EOF
  ```
  
  执行以下命令重新生成etcd证书(重新生成证书之前需要将/etc/kubernetes/pki/etcd目录清空)：
  
  ```shell
  kubeadm init phase certs etcd-ca --config etcd-cert-conf.yaml
  kubeadm init phase certs etcd-server --config etcd-cert-conf.yaml
  kubeadm init phase certs etcd-peer --config etcd-cert-conf.yaml
  kubeadm init phase certs etcd-healthcheck-client --config etcd-cert-conf.yaml
  ```

  3. 更新证书：
  ```shell
  kubeadm alpha certs renew all
  ```