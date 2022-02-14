---
title: 1. Kustomize声明式管理
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
# Kustomize声明式管理

## 1.1. 简介

**本文来自于[官方文档](https://kubernetes.io/zh/docs/tasks/manage-kubernetes-objects/kustomization/)**

Kustomize 是一个独立的工具，用来通过 kustomization 文件 定制 Kubernetes 对象。它提供以下功能特性来管理 应用配置文件：

- 从其他来源生成资源
- 为资源设置贯穿性（Cross-Cutting）字段
- 组织和定制资源集合

从 1.14 版本开始，kubectl 也开始支持使用 kustomization 文件来管理 Kubernetes 对象。 要查看包含 kustomization 文件的目录中的资源，执行下面的命令：

```sh
kubectl kustomize <kustomization_directory>
```

要应用这些资源，使用参数 --kustomize 或 -k 标志来执行 kubectl apply：

```sh
kubectl apply -k <kustomization_directory>
```

## 1.2. 资源配置

### 1.2.1. configMapGenerator

要生成 ConfigMap，可以在 configMapGenerator 中添加对应的表项，主要有`files`、`envs`以及`literals`。

具体示例如下（通过`kubectl kustomize`查看生成结果）：

- 根据文件中的数据生成ConfigMap

```sh
cat <<EOF >tempconfig.properties
VAR01=01
VAR02=02
EOF

cat <<EOF >kustomization.yaml
configMapGenerator:
- name: example-configmap
  files:
  - tempconfig.properties
EOF
```

生成的ConfigMap为：

```yaml
apiVersion: v1
data:
  tempconfig.properties: |
    VAR01=01
    VAR02=02
kind: ConfigMap
metadata:
  name: example-configmap-c2m6bbkcgh
```

- 根据env文件生成ConfigMap

要从 env 文件生成 ConfigMap，请在 configMapGenerator 中的 envs 列表中添加一个条目。

```sh
cat <<EOF >.env
VAR01=01
EOF

cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: example-configmap
  envs:
  - .env
EOF
```

生成的ConfigMap为：

```yaml
apiVersion: v1
data:
  VAR01: "01"
kind: ConfigMap
metadata:
  name: example-configmap-5k57f72dtb
```

**.env 文件中的每个变量在生成的 ConfigMap 中成为一个单独的键。**

- 基于字面的键值对生成ConfigMap

要基于键值偶对来生成 ConfigMap， 在 configMapGenerator 的 literals 列表中添加表项。

```sh
cat <<EOF >./kustomization.yaml
configMapGenerator:
- name: example-configmap
  literals:
  - VAR01=02
EOF
```

生成的ConfigMap为：

```yaml
apiVersion: v1
data:
  VAR01: "02"
kind: ConfigMap
metadata:
  name: example-configmap-7h29bg55cb
```

要在 Deployment 中使用生成的 ConfigMap，使用 configMapGenerator 的名称对其进行引用。 Kustomize 将自动使用生成的名称替换该名称。

```sh
# 创建一个 application.properties 文件
cat <<EOF >application.properties
FOO=Bar
EOF

cat <<EOF >deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: my-app
        volumeMounts:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          name: example-configmap-1
EOF

cat <<EOF >./kustomization.yaml
resources:
- deployment.yaml
configMapGenerator:
- name: example-configmap-1
  files:
  - application.properties
EOF
```

生成的 Deployment 将通过名称引用生成的 ConfigMap：

```yaml
apiVersion: v1
data:
  application.properties: |
        FOO=Bar
kind: ConfigMap
metadata:
  name: example-configmap-1-g4hk9g2ff8
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-app
  name: my-app
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - image: my-app
        name: app
        volumeMounts:
        - mountPath: /config
          name: config
      volumes:
      - configMap:
          name: example-configmap-1-g4hk9g2ff8
        name: config
```

### 1.2.2. secretGenerator

要生成 Secret，可以在 secretGenerator 中添加对应的表项，主要有`files`以及`literals`。

具体示例如下（通过`kubectl kustomize`查看生成结果）：

- 基于文件内容来生成 Secret

要使用文件内容来生成 Secret， 在 secretGenerator 下面的 files 列表中添加表项。

```sh
# 创建一个 password.txt 文件
cat <<EOF >./password.txt
username=admin
password=secret
EOF

cat <<EOF >./kustomization.yaml
secretGenerator:
- name: example-secret-1
  files:
  - password.txt
EOF
```

所生成的 Secret 如下：

```yaml
apiVersion: v1
data:
  password.txt: dXNlcm5hbWU9YWRtaW4KcGFzc3dvcmQ9c2VjcmV0Cg==
kind: Secret
metadata:
  name: example-secret-1-2kdd8ckcc7
type: Opaque
```

- 基于字面的键值对生成ConfigMap

要基于键值偶对字面值生成 Secret，先要在 secretGenerator 的 literals 列表中添加表项。

```sh
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: example-secret-2
  literals:
  - username=admin
  - password=secret
EOF
```

所生成的 Secret 如下：

```yaml
apiVersion: v1
data:
  password: c2VjcmV0
  username: YWRtaW4=
kind: Secret
metadata:
  name: example-secret-2-8c5228dkb9
type: Opaque
```

与 ConfigMaps 一样，生成的 Secrets 可以通过引用 secretGenerator 的名称在部署中使用。

### 1.2.3. generatorOptions