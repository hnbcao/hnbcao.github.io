---
title: kubernetes集群运行问题记录
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
## kubernetes集群运行问题记录

- 集群内部容器无法解析外部DNS

  原因：由于节点名为nodex.domain.xx，集群内部容器的/etc/resolv.conf中search域会domain.xx域，容器在解析外网域名时默认会先在外网域名后添加.domain.xx进行域名解析，而外网存在域名domain.xx，且DNS解析域名为*.domain.xx，所以会将外网域名解析至*.domain.xx对应的IP地址，最终导致容器内部无法访问外网域名。

  解决办法：尽量避免集群内部节点名与外网域名冲突，可采用domain.local结尾等命名方式为节点命名。

- gitlab迁移之后系统异常
  
  原因：集群新建gitlab仓库各组件之间的认证文件与原有gialab不一致，导致恢复数据之后部分组件之间交互异常。

  解决办法：新建gitlab之前，迁移原有gitlab中所有的secret文件。