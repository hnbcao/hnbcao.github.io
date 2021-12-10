---
title: Spring Kafka参数配置详情
---
# Spring Kafka参数配置详情

### 一、全局配置

```
# 用逗号分隔的主机:端口对列表，用于建立到Kafka群集的初始连接。覆盖全局连接设置属性
spring.kafka.bootstrap-servers
# 在发出请求时传递给服务器的ID。用于服务器端日志记录
spring.kafka.client-id，默认无
# 用于配置客户端的其他属性，生产者和消费者共有的属性
spring.kafka.properties.*
# 消息发送的默认主题，默认无
spring.kafka.template.default-topic
```
### 二、生产者


Spring Boot中，Kafka 生产者相关配置(所有配置前缀为spring.kafka.producer.)：

```
# 生产者要求Leader在考虑请求完成之前收到的确认数
spring.kafka.producer.acks
# 默认批量大小。较小的批处理大小将使批处理不太常见，并可能降低吞吐量（批处理大小为零将完全禁用批处理）
spring.kafka.producer.batch-size
spring.kafka.producer.bootstrap-servers
# 生产者可用于缓冲等待发送到服务器的记录的总内存大小。
spring.kafka.producer.buffer-memory
# 在发出请求时传递给服务器的ID。用于服务器端日志记录。
spring.kafka.producer.client-id
# 生产者生成的所有数据的压缩类型
spring.kafka.producer.compression-type
# 键的序列化程序类
spring.kafka.producer.key-serializer
spring.kafka.producer.properties.*
# 大于零时，启用失败发送的重试次数
spring.kafka.producer.retries
spring.kafka.producer.ssl.key-password
spring.kafka.producer.ssl.key-store-location
spring.kafka.producer.ssl.key-store-password
spring.kafka.producer.ssl.key-store-type
spring.kafka.producer.ssl.protocol
spring.kafka.producer.ssl.trust-store-location
spring.kafka.producer.ssl.trust-store-password
spring.kafka.producer.ssl.trust-store-type
# 非空时，启用对生产者的事务支持
spring.kafka.producer.transaction-id-prefix
spring.kafka.producer.value-serializer
```

### 三、消费者

Spring Boot中，Kafka 消费者相关配置(所有配置前缀为spring.kafka.consumer.)：

```yml
# 如果“enable.auto.commit”设置为true，设置消费者偏移自动提交到Kafka的频率，默认值无，单位毫秒(ms)
spring.kafka.consumer.auto-commit-interval
# 当Kafka中没有初始偏移或服务器上不再存在当前偏移时策略设置，默认值无，latest/earliest/none三个值设置
# earliest 当各分区下有已提交的offset时，从提交的offset开始消费；无提交的offset时，从头开始消费
# latest 当各分区下有已提交的offset时，从提交的offset开始消费；无提交的offset时，消费新产生的该分区下的数据
# none topic各分区都存在已提交的offset时，从offset后开始消费；只要有一个分区不存在已提交的offset，则抛出异常
spring.kafka.consumer.auto-offset-reset
# 用逗号分隔的主机:端口对列表，用于建立到Kafka群集的初始连接。覆盖全局连接设置属性
spring.kafka.consumer.bootstrap-servers
# 在发出请求时传递给服务器的ID，用于服务器端日志记录
spring.kafka.consumer.client-id
# 消费者的偏移量是否在后台定期提交
spring.kafka.consumer.enable-auto-commit
# 如果没有足够的数据来立即满足“fetch-min-size”的要求，则服务器在取回请求之前阻塞的最大时间量
spring.kafka.consumer.fetch-max-wait
# 服务器应为获取请求返回的最小数据量。
spring.kafka.consumer.fetch-min-size
# 标识此消费者所属的默认消费者组的唯一字符串
spring.kafka.consumer.group-id
# 消费者协调员的预期心跳间隔时间。
spring.kafka.consumer.heartbeat-interval
# 用于读取以事务方式写入的消息的隔离级别。
spring.kafka.consumer.isolation-level
# 密钥的反序列化程序类
spring.kafka.consumer.key-deserializer
# 在对poll()的单个调用中返回的最大记录数。
spring.kafka.consumer.max-poll-records
# 用于配置客户端的其他特定于消费者的属性。
spring.kafka.consumer.properties.*
# 密钥存储文件中私钥的密码。
spring.kafka.consumer.ssl.key-password
# 密钥存储文件的位置。
spring.kafka.consumer.ssl.key-store-location
# 密钥存储文件的存储密码。
spring.kafka.consumer.ssl.key-store-password
# 密钥存储的类型，如JKS
spring.kafka.consumer.ssl.key-store-type
# 要使用的SSL协议，如TLSv1.2, TLSv1.1, TLSv1
spring.kafka.consumer.ssl.protocol
# 信任存储文件的位置。
spring.kafka.consumer.ssl.trust-store-location
# 信任存储文件的存储密码。
spring.kafka.consumer.ssl.trust-store-password
# 信任存储区的类型。
spring.kafka.consumer.ssl.trust-store-type
# 值的反序列化程序类。
spring.kafka.consumer.value-deserializer
```

### 四、监听器

Spring Boot中，Kafka Listener相关配置(所有配置前缀为spring.kafka.listener.)：

```yml
# ackMode为“COUNT”或“COUNT_TIME”时偏移提交之间的记录数
spring.kafka.listener.ack-count=
spring.kafka.listener.ack-mode
spring.kafka.listener.ack-time
spring.kafka.listener.client-id
spring.kafka.listener.concurrency
spring.kafka.listener.idle-event-interval
spring.kafka.listener.log-container-config
# 如果Broker上不存在至少一个配置的主题（topic），则容器是否无法启动，
# 该设置项结合Broker设置项allow.auto.create.topics=true，如果为false，则会自动创建不存在的topic
spring.kafka.listener.missing-topics-fatal=true
# 非响应消费者的检查间隔时间。如果未指定持续时间后缀，则将使用秒作为单位
spring.kafka.listener.monitor-interval
spring.kafka.listener.no-poll-threshold
spring.kafka.listener.poll-timeout
spring.kafka.listener.type
```

### 五、管理

```yml
spring.kafka.admin.client-id
# 如果启动时代理不可用，是否快速失败
spring.kafka.admin.fail-fast=false
spring.kafka.admin.properties.*
spring.kafka.admin.ssl.key-password
spring.kafka.admin.ssl.key-store-location
spring.kafka.admin.ssl.key-store-password
spring.kafka.admin.ssl.key-store-type
spring.kafka.admin.ssl.protocol
spring.kafka.admin.ssl.trust-store-location
spring.kafka.admin.ssl.trust-store-password
spring.kafka.admin.ssl.trust-store-type
```

### 六、授权服务(JAAS)

```yml
spring.kafka.jaas.control-flag=required
spring.kafka.jaas.enabled=false
spring.kafka.jaas.login-module=com.sun.security.auth.module.Krb5LoginModule
spring.kafka.jaas.options.*
```

### 七、SSL认证

```yml
spring.kafka.ssl.key-password
spring.kafka.ssl.key-store-location
spring.kafka.ssl.key-store-password
spring.kafka.ssl.key-store-type
spring.kafka.ssl.protocol
spring.kafka.ssl.trust-store-location
spring.kafka.ssl.trust-store-password
spring.kafka.ssl.trust-store-type
```

### 八、Stream流处理

```yml
spring.kafka.streams.application-id
spring.kafka.streams.auto-startup
spring.kafka.streams.bootstrap-servers
spring.kafka.streams.cache-max-size-buffering
spring.kafka.streams.client-id
spring.kafka.streams.properties.*
spring.kafka.streams.replication-factor
spring.kafka.streams.ssl.key-password
spring.kafka.streams.ssl.key-store-location
spring.kafka.streams.ssl.key-store-password
spring.kafka.streams.ssl.key-store-type
spring.kafka.streams.ssl.protocol
spring.kafka.streams.ssl.trust-store-location
spring.kafka.streams.ssl.trust-store-password
spring.kafka.streams.ssl.trust-store-type
spring.kafka.streams.state-dir
```
