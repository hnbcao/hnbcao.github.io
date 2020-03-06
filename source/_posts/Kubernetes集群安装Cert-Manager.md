---
title: Kubernetes集群安装Cert Manager
date: 2019-12-31 17:31:17
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
# 安装Cert Manager

## 一、Installing the Chart

[https://cert-manager.io/docs/installation/kubernetes/](https://cert-manager.io/docs/installation/kubernetes/)

## 二、创建ClusterIssuer(集群内所有命名空间公用方案)

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: cluster-letsencrypt-prod
spec:
  acme:
    email: hnbcao@qq.com
    privateKeySecretRef:
      name: cluster-letsencrypt-prod
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - http01:
        ingress:
          class: traefik
```

## 三、创建Issuer(集群内单个命名空间独享方案)

```yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: hnbcao@qq.com
    privateKeySecretRef:
      name: letsencrypt-prod
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - http01:
        ingress:
          class: traefik
```

## 四、Ingress应用ClusterIssuer

```yaml
kind: Ingress
apiVersion: extensions/v1beta1
metadata:
  name: harbor-ingress
  namespace: ns-harbor
  labels:
    app: harbor
    chart: harbor
    heritage: Helm
    release: harbor
  annotations:
    cert-manager.io/cluster-issuer: cluster-letsencrypt-prod
spec:
  tls:
    - hosts:
        - harbor.domian.io
      secretName: harbor-letsencrypt-tls
  rules:
    - host: harbor.domian.io
      http:
        paths:
          - path: /
            backend:
              serviceName: harbor-harbor-portal
              servicePort: 80

```

Ingress通过在annotations中添加cert-manager.io/cluster-issuer: cluster-letsencrypt-prod为ingress中的域名自动生成证书。

## 四、Ingress应用ClusterIssuer

```yaml
kind: Ingress
apiVersion: extensions/v1beta1
metadata:
  name: harbor-ingress
  namespace: ns-harbor
  labels:
    app: harbor
    chart: harbor
    heritage: Helm
    release: harbor
  annotations:
    cert-manager.io/issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - harbor.domian.io
      secretName: harbor-letsencrypt-tls
  rules:
    - host: harbor.domian.io
      http:
        paths:
          - path: /
            backend:
              serviceName: harbor-harbor-portal
              servicePort: 80

```

Ingress通过在annotations中添加cert-manager.io/issuer: letsencrypt-prod为ingress中的域名自动生成证书。

## 结束

- 使用Cert Manager时，ingress中host配置的域名必须指定，不能有通配符；

