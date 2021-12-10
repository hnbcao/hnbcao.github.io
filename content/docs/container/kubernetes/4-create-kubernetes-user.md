---
title: Kubernetes集群创建用户
weight: 34
date: 2019-12-31 17:27:30
top: false
cover: true
toc: false
categories: 运维
tags:
  - Kubernetes 
  - 运维
  - 容器化
  - Kubernetes优化
---
# 创建集群用户

1、创建用户

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata: 
  name: admin-user
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```

2、获取管理员用户的Token，通过执行如下命令获取系统Token信息

```sh
kubectl describe secret admin-user --namespace=kube-system
```

3、导入kubeconfig文件

```sh
DASH_TOCKEN=$(kubectl get secret -n kube-system admin-user-token-4j272 -o jsonpath={.data.token}|base64 -d)

kubectl config set-cluster kubernetes --server=https://172.16.0.9:8443 --kubeconfig=/root/kube-admin.conf

kubectl config set-credentials admin-user --token=$DASH_TOCKEN --kubeconfig=/root/kube-admin.conf

kubectl config set-context admin-user@kubernetes --cluster=kubernetes --user=admin-user --kubeconfig=/root/kube-admin.conf

kubectl config use-context admin-user@kubernetes --kubeconfig=/root/kube-admin.conf

```