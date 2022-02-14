---
title: Centos安装Mysql
weight: 35
---

# Centos安装Mysql

## 1.1 基础准备

- 安装yum-utils

```sh
yum -y install yum-utils
```

- 删除已安装的MySQL（MariaDB）

```sh
# 1. 检查MariaDB
rpm -qa|grep mariadb
# mariadb-server-5.5.60-1.el7_5.x86_64
# mariadb-5.5.60-1.el7_5.x86_64
# mariadb-libs-5.5.60-1.el7_5.x86_64

# 2. 删除mariadb
rpm -e --nodeps mariadb-server
rpm -e --nodeps mariadb
rpm -e --nodeps mariadb-libs

# 3. 检查MySQL
rpm -qa|grep mysql

# 2. 删除MySQL
rpm -e --nodeps xxx
```

## 1.2 安装Mysql

- 下载MySQL源

官网地址：[https://dev.mysql.com/downloads/repo/yum/](https://dev.mysql.com/downloads/repo/yum/)

```sh
# 选择对应的版本进行下载，例如CentOS 7当前在官网查看最新Yum源的下载地址为：
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
```

- 安装MySQL源

```sh
# sudo rpm -Uvh platform-and-version-specific-package-name.rpm
sudo rpm -Uvh mysql80-community-release-el7-3.noarch.rpm
```

- 选择MySQL版本

使用MySQL Yum Repository安装MySQL，默认会选择当前最新的稳定版本，例如通过上面的MySQL源进行安装的话，默安装会选择MySQL 8.0版本，如果就是想要安装该版本，可以直接跳过此步骤，如果不是，比如我这里希望安装MySQL5.7版本，就需要切换版本：

```sh
# 查看当前MySQL Yum Repository中所有MySQL版本y
yum repolist all | grep mysql

# 切换版本
sudo yum-config-manager --disable mysql80-community
sudo yum-config-manager --enable mysql57-community
```

- 安装MySQL

```sh
# 安装MySQL
sudo yum install mysql-community-server

# 启动MySQL
sudo systemctl start mysqld.service

# 开机自启动
sudo systemctl enable mysqld.service
```

- 修改密码

MySQL第一次启动后会创建超级管理员账号root@localhost，初始密码存储在日志文件中：

```sh
sudo grep 'temporary password' /var/log/mysqld.log
```

进入MySQL.

进入之后直接修改密码：

```sql
alter user user() identified by "XXXXXX";
```

设置访问权限

```sql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```


## 1.3 配置Mysql

配置文件位置在/etc/my.cnf，修改该文件对mysql进行配置。

- 设置编码为utf8

```conf
[mysqld]
character_set_server=utf8
init-connect='SET NAMES utf8'
```

## 1.4 主从模式

- 修改配置

主节点：

```conf
# 主从复制配置
# 保证与主节点server-id不一致，该配置为主要配置，其他配置项目可选
server-id=1

# 以下所有配置从节点可忽略

log-bin=mysql-bin
binlog_format=row
# 不需要备份的数据库，可以设置多个数据库，一般不会同步mysql这个库
binlog-ignore-db=mysql
binlog-ignore-db=information_schema
binlog-ignore-db=performance_schema
binlog_ignore_db=sys
# 控制binlog的写入频率。每执行多少次事务写入一次(这个参数性能消耗很大，但可减小MySQL崩溃造成的损失) 
sync_binlog=1                    
# 这个参数一般用在主主同步中，用来错开自增值, 防止键值冲突
auto_increment_offset=1           
# 这个参数一般用在主主同步中，用来错开自增值, 防止键值冲突
auto_increment_increment=1            
# 二进制日志自动删除/过期的天数。默认值为0，表示不自动删除
expire_logs_days=7
# 跳过主从复制中遇到的所有错误或指定类型的错误，避免slave端复制中断。
# 如：1062错误是指一些主键重复，1032错误是因为主从数据库数据不一致
slave_skip_errors=1062
```

从节点：

```conf
# 主从复制配置
log-bin=mysql-bin
server-id=2
binlog_format=row
# 不需要备份的数据库，可以设置多个数据库，一般不会同步mysql这个库
binlog-ignore-db=mysql
binlog-ignore-db=information_schema
binlog-ignore-db=performance_schema
binlog_ignore_db=sys
# 控制binlog的写入频率。每执行多少次事务写入一次(这个参数性能消耗很大，但可减小MySQL崩溃造成的损失) 
sync_binlog=1                    
# 这个参数一般用在主主同步中，用来错开自增值, 防止键值冲突
auto_increment_offset=1           
# 这个参数一般用在主主同步中，用来错开自增值, 防止键值冲突
auto_increment_increment=1            
# 二进制日志自动删除/过期的天数。默认值为0，表示不自动删除
expire_logs_days=7
# 跳过主从复制中遇到的所有错误或指定类型的错误，避免slave端复制中断。
# 如：1062错误是指一些主键重复，1032错误是因为主从数据库数据不一致
slave_skip_errors=1062
```

- 新建同步账号

**主节点**:

新建账户，并授权slave权限

```sql
GRANT REPLICATION SLAVE ON *.* TO 'slave'@'10.75.8.151' IDENTIFIED BY '123@DataBench';
```

查看主节点状态，并记录binlog文件（File）以及偏移量（Position）

```
mysql> SHOW MASTER STATUS;
+------------------+-----------+--------------+-------------------------------------------------+--------------------------------------------------+
| File             | Position  | Binlog_Do_DB | Binlog_Ignore_DB                                | Executed_Gtid_Set                                |
+------------------+-----------+--------------+-------------------------------------------------+--------------------------------------------------+
| mysql-bin.000004 | 129583619 |              | mysql,information_schema,performance_schema,sys | cc2be86e-a98d-11eb-b08c-fa163e2beef8:1-684160635 |
+------------------+-----------+--------------+-------------------------------------------------+--------------------------------------------------+
```

**从节点**:

停止Slave

```sql
stop slave;
```

配置主库连接信息

```sql
// master的ip地址
change master to master_host='192.168.1.205',
// master授权的用户
master_user='username',
// master的授权用户密码
master_password='password',
// master的访问端口  不要带引号，必须是整型，否则会报错
master_port=3306,
// master的binlog日志名称，这里使用上述“1.3”命令搜索出来的为准
master_log_file='mysql-bin.000004',
// master的日志位置 这里使用上述“1.3”命令搜索出来的为准，不能带引号，必须是整型，否则会报错
master_log_pos=129583619,
// 重试时间、单位秒
master_connect_retry=30;
```

启动Slave

```sql
start slave;
```

检查从库状态

```sql
show slave status \G
```

Slave_IO_Running和Slave_SQL_Running为True时表示从库连接主库成功

```
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.75.8.150
                  Master_User: slave
                  Master_Port: 3307
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000004
          Read_Master_Log_Pos: 129583619
               Relay_Log_File: node5-relay-bin.000008
                Relay_Log_Pos: 129583832
        Relay_Master_Log_File: mysql-bin.000004
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 129583619
              Relay_Log_Space: 129584086
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: 41e57c0a-687e-11ec-8b18-08f1ea86c50c
             Master_Info_File: /data/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0.01 sec)
```

参考文章

[https://www.jianshu.com/p/b0cf461451fb](https://www.jianshu.com/p/b0cf461451fb)