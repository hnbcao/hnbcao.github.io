---
title: Docker Compose安装使用
weight: 31
date: 2020-03-17 15:42:28
categories: 运维
tags:
  - Docker 
  - 运维
  - docker-compose
---

# Docker Compose安装使用

### 概述

Compose是用于定义和运行多容器Docker应用程序的工具。通过Compose，您可以使用YAML文件来配置应用程序的服务。然后，使用一个命令，就可以从配置中创建并启动所有服务。

使用Compose基本上是一个三步过程：
 
 - 打包应用镜像
 - 使用docker-compose.yml文件定义应用服务
 - 运行docker-compose up 启动服务

 如下是一个redis服务的docker-compose.yml文件：

 ```yaml
 version: '2.0'
services:
  web:
    build: .
    ports:
    - "5000:5000"
    volumes:
    - .:/code
    - logvolume01:/var/log
    links:
    - redis
  redis:
    image: redis
volumes:
  logvolume01: {}
 ```

 ### 概述

 Compose是用于定义和运行多容器应用的工具。通过Compose，您可以使用YAML文件来配置应用程序的服务。然后，使用一个命令，就可以从配置中创建并启动所有服务。例如：一个Wordpress项目包含mysql数据库和wordpress应用，首先创建docker-compose.yml文件（建议在wordpress文件夹下创建，方便管理），然后在docker-compose.yml文件所在的目录下运行“docker-compose up -d”，Compose就会通过配置创建并启动Wordpress。

 ### 一、安装Docker Compose

 系统环境

| Host Name | OS | IP |
| - | - | - |
| master1 | CentOS 7.5 | 192.168.56.114 |

通过如下命令下载Docker Compose
```sh
# 下载docker-compose-1.25.4并保存至/usr/local/bin/目录下
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# 修改docker-compose权限为可运行
sudo chmod +x /usr/local/bin/docker-compose
```

 ### 二、Compose常用命令简介

 本文只介绍在生产环境中经常会用到的几个命令，关于其他命令，可通过“docker-compose help”命令查询，或者查询[Docker官方网站](https://docs.docker.com/compose/reference/overview/)

 - docker-compose up

 应用启动/更新命令，构建、（重新）创建、启动并附加到服务的容器。“docker-compose up”命令后可跟参数，

 1. -d：后台运行应用，类似docker run -d；
 2. --force-recreate：强制重新生成容器；

其他命令可查询官方文档。

 - docker-compose down

 停止应用所有容器并删除compose创建的网络，存储和容器。

  ### 三、docker-compose.yml介绍

下面是wordpress应用的docker-compose.yml的内容，各部分介绍将会通过该文件展开：

```yaml
version: '3.3'
networks:
  app-tier:
    driver: bridge
services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    networks:
      - app-tier

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - "8000:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    networks:
      - app-tier
volumes:
    db_data: {}
```

  - services

  配置应用运行的服务，wordpress应用配置了mysql数据库服务db和业务应用wordpress。服务配置说明如下：
  
  1. image：服务运行的Docker镜像；
  2. volumes：存储挂载，可挂载应用配置的volumes或者直接挂载宿主机路径,如：“- /opt/mysql/data:/var/lib/mysql”
  3. restart：服务重启策略。always：宕机自动重启；
  4. environment：环境变量配置；
  5. networks：服务网络配置；

  - networks

  配置应用运行的网络，服务通过networks指定镜像运行使用的网络。

  - volumes

  配置存储，服务可通过volumes挂载。





 