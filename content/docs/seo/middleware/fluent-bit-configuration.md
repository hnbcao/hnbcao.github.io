---
title: Fluent-bit日志插件配置说明
weight: 34
---

# Fluent-bit日志插件配置说明

### 一、概述

fluent-bit配置文件中，主要由输入（Input）、解析器（Parser）、过滤器（Filter）、缓存（Buffer）、路由（Routing）、输出（Output）六大模块组成，各个模块的详细说明如下：

![fluent-bit数据流图](/medias/logging_pipeline.png)

|Interface|Description(英文)|Description(中文)|
|-|-|-|
|Input|	Entry point of data. Implemented through Input Plugins, this interface allows to gather or receive data. E.g: log file content, data over TCP, built-in metrics, etc.|数据的入口点。通过输入插件实现，此接口允许收集或接收数据。例如：日志文件内容，TCP上的数据，内置指标等。|
|Parser	|Parsers allow to convert unstructured data gathered from the Input interface into a structured one. Parsers are optional and depends on Input plugins.|解析器允许将从Input接口收集的非结构化数据转换为结构化数据。解析器是可选的，并且取决于Input插件。|
|Filter	|The filtering mechanism allows to alter the data ingested by the Input plugins. Filters are implemented as plugins.|过滤机制允许更改 Input插件提取的数据。过滤器被实现为插件。|
|Buffer|By default, the data ingested by the Input plugins, resides in memory until is routed and delivered to an Output interface.|默认情况下，Input插件提取的数据将驻留在内存中，直到路由并传递到Output接口为止。|
|Routing	|Data ingested by an Input interface is tagged, that means that a Tag is assigned and this one is used to determinate where the data should be routed based on a match rule.|Input接口摄取的数据被标记，这意味着分配了一个Tag，并且该标记用于根据匹配规则确定应将数据路由到的位置。|
|Output	|An output defines a destination for the data. Destinations are handled by output plugins. Note that thanks to the Routing interface, the data can be delivered to multiple destinations.|输出定义数据的目的地。目的地由输出插件处理。请注意，借助“路由”接口，可以将数据传递到多个目的地。|

### 二、配置文件

一个fluent-bit配置文件除了包括输入（Input）、解析器（Parser）、过滤器（Filter）、缓存（Buffer）、路由（Routing）、输出（Output）六个模块外，还需要配置Service，该模块主要负责fluent-bit的配置，如Parser配置文件路径、fluent-bit自身日志打印等。如下是fluent-bit.conf配置：
```
[SERVICE]
    Flush        1
    Daemon       Off
    Log_Level    debug
    Parsers_File parsers.conf
[INPUT]
    Name             tail
    Path             ${K8S_LOG_DIR}/*.log
    Parser           json
    Tag              kube_file.*
    Refresh_Interval 5
    Mem_Buf_Limit    5MB
    Skip_Long_Lines  OFF
[FILTER]
    Name             record_modifier
    Match            kube_file.*
    Record           hostname ${K8S_HOSTNAME}
    Record           namespace ${K8S_POD_NAMESPACE}
    Record           application ${K8S_APPLICATION_NAME}
    Record           pod ${K8S_POD_NAME}
    Record           container ${K8S_CONTAINER_NAME}
    Record           node ${K8S_NODE_NAME}
[OUTPUT]
    Name             es
    Match            *
    Host             ${ELASTICSEARCH_HOST}
    Port             ${ELASTICSEARCH_PORT}
    Logstash_Format  On
    Retry_Limit      False
    Type             flb_type
    Time_Key         time
    Time_Key_Format  yyyy-MM-dd HH:mm:ss.SSS
    Replace_Dots     On
    Logstash_Prefix  segma_application_file
```

### 三、Service

Service各个配置项如下：

|Key|Description|中文描述|Default Value|
|-|-|-|-|
|Flush| Set the flush time in seconds. Everytime it timeouts, the engine will flush the records to the output plugin. | 设置Flush时间（以秒为单位）。每次超时，引擎都会将记录刷新到输出插件。| 5|
|Daemon|Boolean value to set if Fluent Bit should run as a Daemon (background) or not. Allowed values are: yes, no, on and off.	|一个布尔值，用于设置Fluent Bit是否应作为守护程序（后台）运行。允许的值为：是，否，打开和关闭。|Off|
|Log_File|Absolute path for an optional log file.|可选日志文件的绝对路径。|-|
|Log_Level|	Set the logging verbosity level. Allowed values are: error, info, debug and trace. Values are accumulative, e.g: if 'debug' is set, it will include error, info and debug. Note that trace mode is only available if Fluent Bit was built with the WITH_TRACE option enabled.	|设置日志记录的详细程度。允许的值为：error, info, debug 和 trace。值是累积值，例如：如果设置了“ debug”，则它将包括error, info 和 debug。请注意，只有在启用WITH_TRACE选项的情况下构建Fluent Bit时，跟踪模式才可用。|info|
|Parsers_File	|Path for a parsers configuration file. Multiple Parsers_File entries can be used.	|配置文件的路径。可以使用多个Parsers_File条目。 |-|
|HTTP_Server|	Enable built-in HTTP Server	|启用内置的HTTP服务器|Off|
|HTTP_Listen|	Set listening interface for HTTP Server when it's enabled|启用HTTP Server时设置监听接口	|0.0.0.0|
|HTTP_Port|	Set TCP Port for the HTTP Server|设置HTTP服务器的TCP端口|	2020|

在Kubernetes中进行日志收集时，一般需要配置的项有：Flush、Daemon、Log_Level、Parsers_File。在调试插件时，关闭Daemon以及设置Log_Level为debug甚至更高可方便查看插件运行错误。Parsers_File对应解析器的配置，可参考官方提供的[parsers.conf](https://raw.githubusercontent.com/fluent/fluent-bit/master/conf/parsers.conf)

### 四、Input

INPUT模块指点了日志输入源，每个输入插件都可以添加自己的配置键。以下为目前官方支持的输入源插件,[官方Input Plugins](https://fluentbit.io/documentation/0.13/input/)。运行在kubernetes集群内的应用日志收集时，我们使用的是tail插件常用参数如下：

|Key|Description|中文描述|Default|
|-|-|-|-|
|Buffer_Chunk_Size|Set the initial buffer size to read files data. This value is used too to increase buffer size. The value must be according to the Unit Size specification.|设置初始缓冲区大小以读取文件数据。该值也用于增加缓冲区大小。该值必须符合“ 单位大小”规范。|32k|
|Buffer_Max_Size|Set the limit of the buffer size per monitored file. When a buffer needs to be increased (e.g: very long lines), this value is used to restrict how much the memory buffer can grow. If reading a file exceed this limit, the file is removed from the monitored file list. The value must be according to the Unit Size specification.|设置每个受监视文件的缓冲区大小的限制。当需要增加缓冲区时（例如：很长的行），该值用于限制内存缓冲区可以增长多少。如果读取的文件超过此限制，将从监视的文件列表中删除该文件。该值必须符合“ 单位大小”规范。|Buffer_Chunk_Size|
|Path|Pattern specifying a specific log files or multiple ones through the use of common wildcards.|通过使用通用通配符指定一个或多个特定日志文件的模式。|
|Path_Key|If enabled, it appends the name of the monitored file as part of the record. The value assigned becomes the key in the map.|如果启用，它将附加受监视文件的名称作为记录的一部分。分配的值成为映射中的键。|
|Exclude_Path|Set one or multiple shell patterns separated by commas to exclude files matching a certain criteria, e.g: exclude_path=*.gz,*.zip|设置一个或多个用逗号分隔的外壳模式，以排除符合特定条件的文件，例如：exclude_path = *.gz，*.zip|
|Refresh_Interval|The interval of refreshing the list of watched files. Default is 60 seconds.|刷新监视文件列表的时间间隔。默认值为60秒。|
|Rotate_Wait|Specify the number of extra seconds to monitor a file once is rotated in case some pending data is flushed. Default is 5 seconds.|指定在刷新某些未决数据时旋转一次后监视文件的额外秒数。默认值为5秒。|
|Skip_Long_Lines|When a monitored file reach it buffer capacity due to a very long line (Buffer_Max_Size), the default behavior is to stop monitoring that file. Skip_Long_Lines alter that behavior and instruct Fluent Bit to skip long lines and continue processing other lines that fits into the buffer size.|当受监视的文件由于行很长（Buffer_Max_Size）而达到缓冲区容量时，默认行为是停止监视该文件。Skip_Long_Lines会更改该行为，并指示Fluent Bit跳过长行并继续处理适合缓冲区大小的其他行。|Off
|DB|Specify the database file to keep track of monitored files and offsets.|指定数据库文件以跟踪受监视的文件和偏移量。|
|DB.Sync|Set a default synchronization (I/O) method. Values: Extra, Full, Normal, Off. This flag affects how the internal SQLite engine do synchronization to disk, for more details about each option please refer to this section.|设置默认的同步（I / O）方法。值：Extra，Full，Normal，Off。此标志影响内部SQLite引擎与磁盘同步的方式，有关每个选项的更多详细信息，请参阅本节。|Full
|Mem_Buf_Limit|Set a limit of memory that Tail plugin can use when appending data to the Engine. If the limit is reach, it will be paused; when the data is flushed it resumes.|设置将数据附加到引擎时，Tail插件可以使用的内存限制。如果达到极限，它将被暂停；刷新数据后，它将恢复。|
|Parser|Specify the name of a parser to interpret the entry as a structured message.|指定解析器的名称，以将条目解释为结构化消息。|
|Key|When a message is unstructured (no parser applied), it's appended as a string under the key name log. This option allows to define an alternative name for that key.|当消息是非结构化消息（未应用解析器）时，它将作为字符串附加在键名log下。此选项允许为该键定义替代名称。|log|

常用的参数有Path、Parser、Tag、Refresh_Interval、Mem_Buf_Limit、Skip_Long_Lines。Path指定日志所在目录；Tag为Routing参数，会在Routing章节介绍；Refresh_Interval指定日志刷新时间间隔，会直接影响日志收集的实时性，一般设置为5秒；Mem_Buf_Limit指定插件内存大小，一般设置5Mb;Skip_Long_Lines一般使用默认值Off；其中比较重要的是Parser参数的配置，主要匹配Parser解析器，其值为解析器的name值，下一章介绍Parser解析器。

### 五、Parser

Parser解析器的配置是单独的一个配置文件，配置的加载是由Service模块的Parsers_File参数指定。可参考官方提供的[parsers.conf](https://raw.githubusercontent.com/fluent/fluent-bit/master/conf/parsers.conf)

### 六、Filter

Filter插件允许改变输入数据的结构，例如在Kubernetes集群中，我们需要日志记录应用的名字以及所在节点，而默认日志未打印该值，我们便可以使用Filter附加该值。详情见[官方插件](https://fluentbit.io/documentation/0.13/filter/)信息

### 七、Buffer

当准备好将数据或日志路由到某个目标位置时，默认情况下会将它们缓冲在内存中。

### 八、Routing

路由是一项核心功能，可让您通过过滤器将数据路由到一个或多个目的地。路由主要由两个参数控制。
- Tag：当数据由输入插件生成时，它附带一个标签（大多数情况下是手动配置该标签），该标签是人类可读的指示器，有助于识别数据源。
- Match：我们定义其中的数据应被路由，一个匹配规则在配置中进行分配。

下面文件将简单介绍路由规则的实现：
```
[INPUT]
    Name cpu
    Tag  my_cpu

[INPUT]
    Name mem
    Tag  my_mem

[OUTPUT]
    Name   es
    Match  my_cpu

[OUTPUT]
    Name   stdout
    Match  my_mem
```
在上面的配置中，es输出通过Match值my_cpu匹配到输入插件cpu的Tag值，而stdout输出则通过Match值my_mem匹配到输入插件mem的Tag值，所以es输出只接收cpu输出，stdout输出只接收mem输出。

### 九、Output

输出接口允许定义数据的目的地。通用目标是远程服务，本地文件系统或其他标准接口。输出实现为插件，并且有很多可用的插件。
有关更多详细信息，请参阅“[输出插件](https://fluentbit.io/documentation/0.13/output/)”部分。

Filter

### 附录 Fluent-bit官方文档

[https://fluentbit.io/documentation](https://fluentbit.io/documentation/0.13/configuration/file.html)