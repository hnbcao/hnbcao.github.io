# canal安装部署

### 一、概述

canal版本：1.1.5

### 二、安装Zookeeper

### 三、MySQL配置

- 对于自建 MySQL , 需要先开启 Binlog 写入功能，配置 binlog-format 为 ROW 模式，my.cnf 中配置如下

```
[mysqld]
log-bin=mysql-bin # 开启 binlog
binlog-format=ROW # 选择 ROW 模式
server_id=1 # 配置 MySQL replaction 需要定义，不要和 canal 的 slaveId 重复
```

- 授权 canal 链接 MySQL 账号具有作为 MySQL slave 的权限, 如果已有账户可直接 grant

```
CREATE USER canal IDENTIFIED BY 'canal';  
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%';
-- GRANT ALL PRIVILEGES ON *.* TO 'canal'@'%' ;
FLUSH PRIVILEGES;
```

### 四、部署canal-admin

- canal-admin设计上是为canal提供整体配置管理、节点运维等面向运维的功能，提供相对友好的WebUI操作界面，方便更多用户快速和安全的操作

    依赖：MySQL，用于存储配置和节点等相关数据

- 部署

1. 下载 canal-admin, 访问 release 页面 , 选择需要的包下载, 如以 1.1.5 版本为例

```shell
wget https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.admin-1.1.5.tar.gz
```

2. 解压缩

```
export CANAL_DIR=/data/xxxx
mkdir ${CANAL_DIR}/canal-admin
tar zxvf canal.admin-$version.tar.gz  -C ${CANAL_DIR}/canal-admin
```

解压完成后，进入 ${CANAL_DIR}/canal 目录，可以看到如下结构

```shell
drwxr-xr-x   6 agapple  staff   204B  8 31 15:37 bin
drwxr-xr-x   8 agapple  staff   272B  8 31 15:37 conf
drwxr-xr-x  90 agapple  staff   3.0K  8 31 15:37 lib
drwxr-xr-x   2 agapple  staff    68B  8 31 15:26 logs
```

3. 配置修改

cannal服务本身需要使用mysql存储数据，与cannal监控的mysql可以不是同一个。

需要修改的部分为：

```yaml
spring.datasource:
  address: 127.0.0.1:3307
  database: canal_manager
  username: root
  password: 123@DataBench
```

```yaml
# vi conf/application.yml
server:
  port: 8089
spring:
  jackson:
    date-format: yyyy-MM-dd HH:mm:ss
    time-zone: GMT+8

spring.datasource:
  address: 127.0.0.1:3307
  database: canal_manager
  username: root
  password: 123@DataBench
  driver-class-name: com.mysql.jdbc.Driver
  url: jdbc:mysql://${spring.datasource.address}/${spring.datasource.database}?useUnicode=true&characterEncoding=UTF-8&useSSL=false
  hikari:
    maximum-pool-size: 30
    minimum-idle: 1

canal:
  adminUser: admin
  adminPasswd: 123@DataBench  # 使用mysql调用password函数，查看adminPasswd加密后的结果并记录，后续deployer会用到。
```

** 记住这里的

4. 初始化元数据库

```
mysql -h127.0.0.1 -uroot -p
# 导入初始化SQL
> source conf/canal_manager.sql

```

a. 初始化SQL脚本里会默认创建canal_manager的数据库，建议使用root等有超级权限的账号进行初始化 

b. canal_manager.sql默认会在conf目录下，其内容为：

```sql
CREATE DATABASE /*!32312 IF NOT EXISTS*/ `canal_manager` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_bin */;

USE `canal_manager`;

SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for canal_adapter_config
-- ----------------------------
DROP TABLE IF EXISTS `canal_adapter_config`;
CREATE TABLE `canal_adapter_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `category` varchar(45) NOT NULL,
  `name` varchar(45) NOT NULL,
  `status` varchar(45) DEFAULT NULL,
  `content` text NOT NULL,
  `modified_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for canal_cluster
-- ----------------------------
DROP TABLE IF EXISTS `canal_cluster`;
CREATE TABLE `canal_cluster` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(63) NOT NULL,
  `zk_hosts` varchar(255) NOT NULL,
  `modified_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for canal_config
-- ----------------------------
DROP TABLE IF EXISTS `canal_config`;
CREATE TABLE `canal_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cluster_id` bigint(20) DEFAULT NULL,
  `server_id` bigint(20) DEFAULT NULL,
  `name` varchar(45) NOT NULL,
  `status` varchar(45) DEFAULT NULL,
  `content` text NOT NULL,
  `content_md5` varchar(128) NOT NULL,
  `modified_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sid_UNIQUE` (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for canal_instance_config
-- ----------------------------
DROP TABLE IF EXISTS `canal_instance_config`;
CREATE TABLE `canal_instance_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cluster_id` bigint(20) DEFAULT NULL,
  `server_id` bigint(20) DEFAULT NULL,
  `name` varchar(45) NOT NULL,
  `status` varchar(45) DEFAULT NULL,
  `content` text NOT NULL,
  `content_md5` varchar(128) DEFAULT NULL,
  `modified_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_UNIQUE` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for canal_node_server
-- ----------------------------
DROP TABLE IF EXISTS `canal_node_server`;
CREATE TABLE `canal_node_server` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cluster_id` bigint(20) DEFAULT NULL,
  `name` varchar(63) NOT NULL,
  `ip` varchar(63) NOT NULL,
  `admin_port` int(11) DEFAULT NULL,
  `tcp_port` int(11) DEFAULT NULL,
  `metric_port` int(11) DEFAULT NULL,
  `status` varchar(45) DEFAULT NULL,
  `modified_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for canal_user
-- ----------------------------
DROP TABLE IF EXISTS `canal_user`;
CREATE TABLE `canal_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(31) NOT NULL,
  `password` varchar(128) NOT NULL,
  `name` varchar(31) NOT NULL,
  `roles` varchar(31) NOT NULL,
  `introduction` varchar(255) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `creation_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS = 1;

-- ----------------------------
-- Records of canal_user
-- ----------------------------
BEGIN;
INSERT INTO `canal_user` VALUES (1, 'admin', '6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9', 'Canal Manager', 'admin', NULL, NULL, '2019-07-14 00:05:28');
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
```

5. 启动

```
sh bin/startup.sh

```
查看 admin 日志

```
vi logs/admin.log

2019-08-31 15:43:38.162 [main] INFO  o.s.boot.web.embedded.tomcat.TomcatWebServer - Tomcat initialized with port(s): 8089 (http)
2019-08-31 15:43:38.180 [main] INFO  org.apache.coyote.http11.Http11NioProtocol - Initializing ProtocolHandler ["http-nio-8089"]
2019-08-31 15:43:38.191 [main] INFO  org.apache.catalina.core.StandardService - Starting service [Tomcat]
2019-08-31 15:43:38.194 [main] INFO  org.apache.catalina.core.StandardEngine - Starting Servlet Engine: Apache Tomcat/8.5.29
....
2019-08-31 15:43:39.789 [main] INFO  o.s.w.s.m.m.annotation.ExceptionHandlerExceptionResolver - Detected @ExceptionHandler methods in customExceptionHandler
2019-08-31 15:43:39.825 [main] INFO  o.s.b.a.web.servlet.WelcomePageHandlerMapping - Adding welcome page: class path resource [public/index.html]

```

此时代表canal-admin已经启动成功，可以通过 http://127.0.0.1:8089/ 访问，默认密码：admin/123456

6. 配置Canal

> 1.打开canal-admin(http://127.0.0.1:8089)，点击新建集群，填写集群名和zk地址(部署canal-deployer时间使用的zk)
>
> 2.新建完成之后点击集群操作按钮下拉选择主配置，然后在新页面点击载入模板并保存

### 五、启动canal-deployer

- 下载 canal, 访问 release 页面 , 选择需要的包下载, 选择 1.1.5 版本

```shell
wget https://github.com/alibaba/canal/releases/download/canal-1.1.5/canal.deployer-1.1.5.tar.gz
```

- 解压缩

```shell
export CANAL_DIR=/data/xxx # 自定义
mkdir ${CANAL_DIR}/canal-deployer
tar zxvf canal.deployer-1.1.5.tar.gz  -C ${CANAL_DIR}/canal-deployer
```

解压完成后，进入 ${CANAL_DIR}/canal-deployer 目录，可以看到如下结构

```shell
drwxr-xr-x 2 hnbcao hnbcao  136 2013-02-05 21:51 bin
drwxr-xr-x 4 hnbcao hnbcao  160 2013-02-05 21:51 conf
drwxr-xr-x 2 hnbcao hnbcao 1.3K 2013-02-05 21:51 lib
drwxr-xr-x 2 hnbcao hnbcao   48 2013-02-05 21:29 logs
```

- 将canal_local.properties文件内容覆盖到canal.properties并编辑canal.properties。

**_需要修改部分_**：

***canal.admin.passwd使用前面admin中application.yml配置的canal.adminPasswd的值使用mysql调用password函数加密后的结果，sql语句为`select password('canal.adminPasswd的值');`***

```properties
# register ip to zookeeper
canal.register.ip = 10.75.8.151 # deployer节点所在服务器IP
canal.port = 11111
canal.metrics.pull.port = 11112
canal.zkServers = 10.75.8.152:2181 # 所在集群的zk地址

# canal admin config
canal.admin.manager = 10.75.8.152:8089 # admin地址
canal.admin.port = 11110
canal.admin.user = admin # admin用户名
canal.admin.passwd = 436ADFAD4F71E49B2E38A8F3A09525B9CD850989 # admin密码，application.yml中配置的密码加密值
# admin auto register
canal.admin.register.auto = true
canal.admin.register.cluster = databench-pro # 集群名，admin部署步骤的最后一步配置中新增的集群名
canal.admin.register.name = node5 # 服务名
```

- 启动canal-deployer

```shell
sh bin/startup.sh
```

启动成功后，会在admin ui上看到新增的节点。

### 六、创建实例（Instance）

* canal admin web页面上选择Instance管理，新建实例，选择集群，设置instance名称，点击载入模版。模版中需要修改以下几项。

***instance名称很重要，连接canal的时候会需要，也就是连接配置destination的值***

```
canal.instance.master.address=10.73.13.59:31308
canal.instance.dbUsername=canal_pro
canal.instance.dbPassword=123@DataBench
```

他们是需要监控的数据库的连接地址和用户名密码