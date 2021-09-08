---
title: CentOS离线镜像仓库创建
date: 2021-02-24 10:08:41
categories: 运维
tags:
- 运维
---

# CentOS离线镜像仓库创建-以base仓库为例

### 一、安装相关软件

```sh
yum install createrepo  reposync  yum-utils -y
```

### 二、替换镜像源

1. 备份

```sh
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
```

2. 下载新的 CentOS-Base.repo 到 /etc/yum.repos.d/

- Aliyun源地址为：https://developer.aliyun.com/mirror/

CentOS 7

```sh
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
```

或者

```sh
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
```

### 三、同步镜像&创建本地仓库

```sh
# 新建文件夹，存储同步的仓库数据
mkdir -p /data/yum.repo && cd /data/yum.repo
# 镜像仓库同步
reposync -r base -p ./
# 创建本地仓库
cd base && createrepo ./
```

### 四、离线服务器使用

1. 将同步的镜像仓库打包到离线服务器上，并解压至/mnt/yum.repo/base/下

2. 备份

```sh
mkdir /etc/yum.repos.d/backup
mv /etc/yum.repos.d/* /etc/yum.repos.d/backup
```

3. 创建新的 repo 文件 到 /etc/yum.repos.d/

```sh
[base]
name=CentOS-$releasever - Base - local-base-repo
failovermethod=priority
baseurl=file:///mnt/yum.repo/base/
gpgcheck=0
```
4. 运行 yum makecache 生成缓存

### 五、定时同步脚本

- 该脚本同步kubernetes相关yum rpm源，定时同步使用crontab 加入该脚本即可，手动同步直接运行该脚本。脚本需要放置在本地保存yum源所在的目录。

```shell
#!/bin/bash
BASE_DIR=$(pwd)
echo "base dir is ${BASE_DIR}"
repolist=("base" "docker-ce-stable" "extras" "kubernetes" "updates")
for repo in ${repolist[@]}; do
  echo "sync repo $repo begin"
  reposync -r ${repo} -p ${BASE_DIR}
  echo "sync repo $repo end"
  echo "rebuild repo $repo begin"
  createrepo --update ${BASE_DIR}/${repo}
  echo "rebuild repo $repo end"
done
```
