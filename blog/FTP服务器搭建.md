---
title: FTP服务器搭建
date: 2020-02-19 08:48:00
top: false
cover: true
toc: true
categories: 运维
tags: 
  - FTP 
  - 运维
  - 共享存储
---

# FTP服务搭建


- 系统： centos 7.4

### 一、安装vsftpd

```sh
yum -y install vsftpd
```

### 二、配置服务

```sh
[root@ecs-7fd0 vsftpd]# cat /etc/vsftpd/vsftpd.conf
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
xferlog_std_format=YES
ascii_upload_enable=YES
ascii_download_enable=YES
chroot_local_user=YES
listen=NO
listen_ipv6=YES

connect_from_port_20=NO

#设置使用主动模式
pasv_enable=YES
pasv_min_port=1024
pasv_max_port=65536

pam_service_name=vsftpd
guest_enable=YES
#设置使用虚拟用户的真实访问用户
guest_username=ftpuser
user_config_dir=/etc/vsftpd/vsftpd_user_conf
allow_writeable_chroot=YES
#设置使用虚拟用户
virtual_use_local_privs=YES
userlist_enable=YES
userlist_deny=NO
tcp_wrappers=YES

```

### 三、创建ftpuser账户

```sh
useradd -d /home/ftpuser -s /sbin/nologin ftpuser
```

### 三、虚拟用户

- 设置pam策略

```sh
[root@ecs-7fd0 vsftpd]# cat /etc/pam.d/vsftpd
#%PAM-1.0
#session    optional     pam_keyinit.so    force revoke
#auth       required	pam_listfile.so item=user sense=deny file=/etc/vsftpd/ftpusers onerr=succeed
#auth       required	pam_shells.so
#auth       include	password-auth
#account    include	password-auth
#session    required     pam_loginuid.so
#session    include	password-auth
auth       required    pam_userdb.so   db=/etc/vsftpd/vsftpd_login
account    required    pam_userdb.so   db=/etc/vsftpd/vsftpd_login
```

- 配置虚拟账户

```sh
[root@ecs-7fd0 vsftpd]# cat ftp_virtual_user 
User001
PasswordForUser001
User002
PasswordForUser002
User003
PasswordForUser003

```

- 生成虚拟账号数据库

```sh
[root@ecs-7fd0 vsftpd]# db_load -T -t hash -f /etc/vsftpd/ftp_virtual_user /etc/vsftpd/vsftpd_login.db
```

- 配置虚拟账户访问目录

```sh

[root@ecs-7fd0 vsftpd]# mkdir -p /etc/vsftpd/vsftpd_user_conf

[root@ecs-7fd0 vsftpd]# cat User001
local_root=/home/ftpuser/User001
write_enable=YES
anon_world_readable_only=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES

[root@ecs-7fd0 vsftpd]# cat User002
local_root=/home/ftpuser/User002
write_enable=YES
anon_world_readable_only=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES

[root@ecs-7fd0 vsftpd]# cat User003
local_root=/home/ftpuser/User003
write_enable=YES
anon_world_readable_only=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
```

- 启动vsftpd

```sh
[root@ecs-7fd0 vsftpd]# systemctl enable vsftpd
[root@ecs-7fd0 vsftpd]# systemctl start vsftpd
```