---
title: Flink On CDH Parcel包创建
weight: 32
---

1、下载Flink源代码

下载地址：https://flink.apache.org/downloads.html

2、编译Flink

- 环境准备

  JDK-1.8、Git、Maven-3.6.3、Node-v12.19.0

- 配置修改

parent项目的pom.xml中增加proflie

```xml
<profile>
	<id>vendor-repos</id>
	<activation>
		<property>
			<name>vendor-repos</name>
		</property>
	</activation>
	<!-- Add vendor maven repositories -->
	<repositories>
		<!-- Cloudera -->
		<repository>
			<id>cloudera-releases</id>
			<url>https://repository.cloudera.com/artifactory/cloudera-repos</url>
			<releases>
				<enabled>true</enabled>
			</releases>
			<snapshots>
				<enabled>false</enabled>
			</snapshots>
		</repository>
		<!-- Hortonworks -->
		<repository>
			<id>HDPReleases</id>
			<name>HDP Releases</name>
			<url>https://repo.hortonworks.com/content/repositories/releases/</url>
			<snapshots><enabled>false</enabled></snapshots>
			<releases><enabled>true</enabled></releases>
		</repository>
		<repository>
			<id>HortonworksJettyHadoop</id>
			<name>HDP Jetty</name>
			<url>https://repo.hortonworks.com/content/repositories/jetty-hadoop</url>
			<snapshots><enabled>false</enabled></snapshots>
			<releases><enabled>true</enabled></releases>
		</repository>
		<!-- MapR -->
		<repository>
			<id>mapr-releases</id>
			<url>https://repository.mapr.com/maven/</url>
			<snapshots><enabled>false</enabled></snapshots>
			<releases><enabled>true</enabled></releases>
		</repository>
	</repositories>
</profile>
```

flink-runtime-web项目下node打包配置中增加npm淘宝源代理

```
<plugin>
    <groupId>com.github.eirslett</groupId>
    <artifactId>frontend-maven-plugin</artifactId>
    <version>1.6</version>
    <executions>
        <execution>
            <id>install node and npm</id>
            <goals>
                <goal>install-node-and-npm</goal>
            </goals>
            <configuration>
                <nodeVersion>v10.9.0</nodeVersion>
            </configuration>
        </execution>
        <execution>
            <id>npm install</id>
            <goals>
                <goal>npm</goal>
            </goals>
            <configuration>
                <arguments>ci -registry=https://registry.npm.taobao.org --cache-max=0 --no-save</arguments>
                <environmentVariables>
                    <HUSKY_SKIP_INSTALL>true</HUSKY_SKIP_INSTALL>
                </environmentVariables>
            </configuration>
        </execution>
        <execution>
            <id>npm run build</id>
            <goals>
                <goal>npm</goal>
            </goals>
            <configuration>
                <arguments>run build -registry=https://registry.npm.taobao.org</arguments>
            </configuration>
        </execution>
    </executions>
    <configuration>
        <workingDirectory>web-dashboard</workingDirectory>
    </configuration>
</plugin>
```

- 开始编译

```sh
#开始编译
mvn clean install -DskipTests -Dfast -Drat.skip=true -Dhaoop.version=3.0.0-cdh6.3.3 -Pvendor-repos -Dinclude-hadoop -Dscala-2.11 -T4C

参数说明
# -Dfast  #在flink根目录下pom.xml文件中fast配置项目中含快速设置,其中包含了多项构建时的跳过参数. #例如apache的文件头(rat)合法校验，代码风格检查，javadoc生成的跳过等，详细可阅读pom.xml
# install maven的安装命令
# -T4C #支持多处理器或者处理器核数参数,加快构建速度,推荐Maven3.3及以上
# -Pinclude-hadoop  将hadoop的 jar包，打入到lib/中
# -Pvendor-repos   # 如果需要指定hadoop的发行商，如CDH，需要使用-Pvendor-repos
# -Dscala-2.11     # 指定scala的版本为2.11
# -Dhadoop.version=3.0.0-cdh6.3.3  指定 hadoop 的版本，这里的版本与CDH集群版本的Hadoop一致就行

#  Flink1.10与Flink1.11的版本编译没有太大差异，需要了解的是

#  Flink1.11使用的是flink-shaded release-11.0版本，已经移除掉了flink-shaded-hadoop-2模块，故在最终生成的flink编译后目录中不会有flink-shaded-hadoop-2-uber包
#  Flink1.10使用的是flink-shaded release-9.0的版本，如果在maven编译的过程中，无法下载flink-shaded-hadoop-2-uber-2.7.5-9.0.jar，下载wget https://github.com/apache/flink-shaded/archive/release-9.0.zip，
编译：mvn clean install -T4C -Pinclude-hadoop -Dhadoop.version=2.7.5 -DskipTests -Dscala-2.11

# 不推荐以Scala版本为2.12编译，在启动start-scala-shell.sh的时候会报错，错误信息为： Error: Could not find or load main class org.apache.flink.api.scala.FlinkShell
#  这是 flink 的一个 bug，基于 scala 2.12 编译的 flink 会存在这个问题，使用基于 scala 2.11 编译的 flink 就不会有这个问题了。这个 bug 之后应该会修复，当前已知在 flink 1.11 中这个问题依然存在。

```

- 压缩flink安装包

```
cd flink-release-1.13.1/flink-dist/target/flink-1.13.1-bin/flink-1.13.1
tar zcvf flink-1.13.1-cdh6.3.0.tgz flink-1.10.2
```


3、parcel包制作

- 下载https://github.com/hnbcao/flink-parcel，并将打包好的flink拷贝到flink-parcel下。

- 配置打包程序

```sh
cd flink-parcel
vim flink-parcel.properties
```
```
#FLINk 下载地址
#FLINK_URL=  /Users/guiyifei/Dev/learn/flink/flink-dist/target/flink-1.12.4-bin/flink-1.12.4-cdh6.2.1-0001.tgz
FLINK_URL=/data/flink-parcel/flink-parcel/flink-1.13.1.tgz

#flink版本号
FLINK_VERSION=1.13.1

#扩展版本号
EXTENS_VERSION=CDH6.3.0

#操作系统版本，以centos为例
OS_VERSION=7

#CDH 小版本
CDH_MIN_FULL=6.2
CDH_MAX_FULL=6.4

#CDH大版本
CDH_MIN=5
CDH_MAX=6

```

- 制作parcel包

```sh
sh build.sh parcel
# 生成的parcel包在FLINK-1.13.1-CDH6.3.0_build目录下
```

- 制作CSD文件

```sh
sh build.sh csd
生成的csd为 FLINK_ON_YARN-1.13.1.jar
```

4、CDH部署Flink

在flink-parcel-master目录下会生成FLINK_ON_YARN-1.10.2.jar，在FLINK-1.10.2-CDH6.3.3-0001_build目录下会生成FLINK-1.10.2-CDH6.3.3-0001-el7.parcel FLINK-1.10.2-CDH6.3.3-0001-el7.parcel.sha manifest.json 3个文件

```sh
#在CDH 主节点进行操作
#将原来的manifest.json备份
mv /opt/cloudera/parcel-repo/manifest.json /opt/cloudera/parcel-repo/manifest.back.json
cp FLINK_ON_YARN-1.10.2.jar  /opt/cloudera/csd/ 
cp FLINK-1.10.2-CDH6.3.3-0001_build/* /opt/cloudera/parcel-repo/ 
systemctl restart cloudera-scm-server
```

安装：CDH界面操作

5、Flink On Yarn Session HA

见https://www.jianshu.com/p/8f1e650ebcad