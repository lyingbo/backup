---
title: 基于Docker搭建Hadoop集群
category: Hadoop
date: 2019-08-13
---

将Hadoop打包到Docker镜像中，就可以快速的在单个机器上搭建Hadoop集群，这样可以方便新手测试和学习。

Hadoop的master和slave分别运行在不同的Docker容器中，其中NameNode、ResourceManager运行在hadoop-master容器中，DataNode、NodeManager运行在hadoop-slave容器中。NameNode和DataNode是Hadoop分布式文件系统HDFS的组件，负责储存输入以及输出数据，而ResourceManager和NodeManager是Hadoop集群资源管理系统YARN的组件，负责CPU和内存资源的调度。

接下来将以Ubuntu16.04为基镜像，介绍搭建Hadoop3.2.0伪分布式集群运行环境的步骤：

##  
### A. 3节点Hadoop集群搭建步骤:

##### 1. 下载Docker镜像
```
sudo docker pull lyingbo/hadoop:3.2.0
```

##### 2. 下载shell脚本
```
git clone https://github.com/lyingbo/hadoop-cluster-docker.git
```

##### 3. 运行Docker容器
```
cd hadoop-cluster-docker
sudo ./start-container.sh
```

**运行结果:**
```
start hadoop-master container...
start hadoop-slave1 container...
start hadoop-slave2 container...
root@hadoop-master:/# 
```
- 启动了3个容器，1个master，2个slave
- 运行后就进入了hadoop-master容器的/root目录

##### 4. 启动hadoop集群
```
start-all.sh
```

**运行结果:**
```
Starting namenodes on [hadoop-master]
hadoop-master: Warning: Permanently added 'hadoop-master,172.18.0.2' (ECDSA) to the list of known hosts.
Starting datanodes
hadoop-slave2: Warning: Permanently added 'hadoop-slave2,172.18.0.4' (ECDSA) to the list of known hosts.
hadoop-slave1: Warning: Permanently added 'hadoop-slave1,172.18.0.3' (ECDSA) to the list of known hosts.
Starting secondary namenodes [hadoop-master]
Starting resourcemanager
Starting nodemanagers
```

##### 5. 运行wordcount示例
```
run-wordcount.sh
```

**运行结果:**
```
input file1.txt:
Hello Docker

input file2.txt:
Hello Hadoop

input file3.txt:
Hello MapReduce

wordcount output:
Docker  1
Hadoop  1
Hello   3
MapReduce       1
```

##  
### B. N节点Hadoop集群搭建步骤:

##### 1. 准备
```
参考A部分2.下载shell脚本
```

##### 2. 重新构建Docker镜像
```
sudo ./resize-cluster.sh 5
```
- 可以指定任意N(N>1)


##### 3. 启动Docker容器
```
sudo ./start-container.sh 5
```
- 与前一步中的N保持一致。

##### 4. 运行Hadoop 
```
参考A部分4~6.启动Hadoop，并运行wordcount。
```
