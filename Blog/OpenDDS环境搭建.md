---
title: OpenDDS环境搭建
category: OpenDDS
date: 2014-03-06
comments: true
tags:
- OpenDDS
- 环境搭建
- MPC
---

以下以Linux系统下的用户DDS为例(关于Windows系统下的搭建过程，跟Linux系统步骤基本一样，请参考文后的评论)，编译OpenDDS源码需要ACE+TAO框架支持，因此需要先编译ACE+TAO的相关库，具体步骤如下：

## 1、下载ACE和DDS源码：

ACE源码：http://www.theaceorb.com/downloads
DDS源码：http://download.ociweb.com/OpenDDS

## 2、拷贝源码包到/WorkSpace目录：

切换到root用户，在根目下创建WorkSpace目录，为WorkSpace目录给所有用户添加+w权限(chmod +w)，再切回到原来的DDS用户，将下载的ACE和DDS源码拷贝到WorkSpace目录下并解压，
```
$cp ACE+TAO-2.2a.tar.gz /WorkSpace
$cp OpenDDS3.5.tar.gz   /WorkSpace
$cd /WorkSpace
$tar –xzvf ACE+TAO-6.1.0.tar.gz
$tar –xzvf OpenDDS3.5.tar.gz
```

## 3、配置ACE和DDS环境变量：

在/home/DDS/.bashrc文件最后加入下面几行：
```
export ACE_ROOT=/WorkSpace/ACE_wrappers
export TAO_ROOT=$ACE_ROOT/TAO
export DDS_ROOT=/WorkSpace/DDS
export PATH=$ACE_ROOT/bin: $DDS_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$ACE_ROOT/lib:$DDS_ROOT/lib:$LD_LIBRARY_PATH
```
使用source /home/DDS/.bashrc命令或者重新登陆终端使环境变量生效

## 4、准备系统相关配置文件：

创建文件/WorkSpace/ACE_wrappers/ace/config.h，写入如下内容：
```
#include "ace/config-linux.h"
```
创建文件/WorkSpace/ACE_wrappers/include/makeinclude/platform_macros.GNU，写入如下内容：
```
debug=0
include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU
```

## 5、编译ACE和DDS源码：

由于ACE+TAO以及DDS源码中提供了许多测试程序，如果所有源码都编译，将非常耗时，可以只编译ACE+TAO中会被DDS用到的部分，以及DDS的核心部分源码。如此，就需要手动重新生成makefile文件，这里可以借助ACE的MPC工具来完成，先在$DDS_ROOT目录下编写一个DDS_TAO_Simple.mwc文件，内容如下：
```
workspace {
  $(ACE_ROOT)/ace/ace.mpc
  $(ACE_ROOT)/apps/gperf/src
  $(TAO_ROOT)/TAO_IDL
  $(TAO_ROOT)/tao/tao.mpc
  $(TAO_ROOT)/tao/AnyTypeCode/AnyTypeCode.mpc
  $(TAO_ROOT)/tao/Codeset/Codeset.mpc
  $(TAO_ROOT)/tao/IORTable/IORTable.mpc
  $(TAO_ROOT)/tao/PortableServer/PortableServer.mpc
  $(TAO_ROOT)/tao/IORManipulation/IORManipulation.mpc
  $(TAO_ROOT)/tao/ImR_Client/ImR_Client.mpc
  $(TAO_ROOT)/tao/PI/PI.mpc
  $(TAO_ROOT)/tao/CodecFactory/CodecFactory.mpc
  $(TAO_ROOT)/orbsvcs/orbsvcs/Svc_Utils.mpc
  dds

  exclude {
    dds/DCPS/QOS_XML_Handler
    DevGuideExamples
    tools
    java
  }
}
```
之后在$DDS_ROOT目录下使用mwc.pl -type gnuace DDS_TAO_Simple.mwc -include $DDS_ROOT/MPC/config命令就可以生成需要的makefile了。

之后执行(cd $DDS_ROOT; make clean && make) 1> make-dds.log 2>make-dds-err.log命令完成ACE和DDS的编译，如果编译出错，可以查看log文件的编译过程，待脚本运行完成，整个OpenDDS的开发环境就搭建好了，可以用来进行基于OpenDDS的二次开发了。
 
如果需要运行DDS的测试程序，cd到测试程序源码目录使用make命令就可以编译执行了。

有关OpenDDS的相关问题欢迎发送邮件至lyingbo@aliyun.com一起讨论
