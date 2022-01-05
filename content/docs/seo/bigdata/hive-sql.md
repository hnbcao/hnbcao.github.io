---
title: Hive SQL操作指南
weight: 31
---

# Hive操作指南

## 1.1 CREATE DATABASE

```sql
CREATE DARABASE name;
```

```sql
show tables; --显示表

show databases; --显示数据库

show partitions table_name; --显示表名为table_name的表的所有分区

show functions ; --显示所有函数

describe extended table_name col_name; --查看表中字段
```

## 1.2 DDL(Data Defination Language)

### 1.2.1 CREATE TABLE

```sql
CREATE [EXTERNAL] TABLE [IF NOT EXISTS] table_name

[(col_name data_type [COMMENT col_comment], ...)]

[COMMENT table_comment]

[PARTITIONED BY (col_name data_type [COMMENT col_comment], ...)]

[CLUSTERED BY (col_name, col_name, ...)

[SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]

[ROW FORMAT row_format]

[STORED AS file_format]

[LOCATION hdfs_path]
```

- CREATE TABLE 创建一个指定名字的表。如果相同名字的表已经存在，则抛出异常；用户可以用 IF NOT EXIST 选项来忽略这个异常

- EXTERNAL 关键字可以让用户创建一个外部表，在建表的同时指定一个指向实际数据的路径（LOCATION）

- LIKE 允许用户复制现有的表结构，但是不复制数据

- COMMENT可以为表与字段增加描述

- ROW FORMAT 设置行数据分割格式

eg:
```sql
CREATE TABLE IF NOT EXISTS `table_name` (
`row01` BIGINT COMMENT 'COMMENT01',
`row02` STRING COMMENT 'COMMENT02',
`row03` TINYINT COMMENT 'COMMENT03',
`row04` DOUBLE COMMENT 'COMMENT04',
`row05` STRING COMMENT 'COMMENT05')
PARTITIONED BY (`partition_name` string COMMENT 'partition comment')
STORED AS PARQUET TBLPROPERTIES('parquet.compression'='SNAPPY');
```

- INSERT DATA

```sql
INSERT INTO TABLE test1
PARTITION (p_day="2021-12-20")
VALUES (123,'1',1,2,'3');
```

