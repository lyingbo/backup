---
title: 基于OpenDDS应用程序开发(1)IDL定义
category: OpenDDS
date: 2014-07-02
---

连续的三篇博文演示如何基于OpenDDS开发应用程序，将数据从发布端节点发送到订阅端节点，该示例程序由一个发布者发布数据，一个订阅者订阅数据，使用默认的QoS策略和TCP/IP传输方式。

本文是第一篇，主要介绍IDL的定义及编译。

## 1、IDL定义：

DDS中的数据类型需要通过IDL格式定义，OpenDDS使用#pragma关键字定义DDS传输和处理的数据类型。
这些数据类型再由tao_idl编译器和OpenDDS_idl编译器进行预编译出来，生成用于网络传输这些数据类型的代码。

下面是一个定义Demo数据类型的IDL文件：
```
module Demo {

#pragma DCPS_DATA_TYPE "Demo::Pos"
#pragma DCPS_DATA_KEY "Demo::Pos.pos_id"

    struct Pos {
        long pos_id;
        long pos_x;
        long pos_y;
    };
};
```
IDL文件使用DCPS_DATA_TYPE定义一个结构体数据类型，IDL语法要求每个类型定义必须以该关键字开头。OpenDDS规定数据类型必须为一个结构体，结构体中可包含标量类型（short、long、float等）、枚举类型、字符串、队列、数组、结构体、以及它们的组合。本例中在demo模块中定义了一个结构体pos。

使用DCPS_DATA_KEY定义一个数据类型的键，一种数据类型可以有0个或多个键，这些键用于区分同一个主题内的不同实体。每个键必须是数值型、枚举型、字符串或者这些类型的typedef。DCPS_DATA_KEY限定了作用域的数据类型以及成员名，成员名标识为该类型的键，多个键由多个DCPS_DATA_KEY指定。在上面的IDL定义中，指定了pos_id作为Demo::Pos的键。每个样本发布时带有一个唯一的pos_id值，这样就可以区分同一主题中的不同实例。由于使用了默认的QoS策略，随后带有相同pos_id值的样本就会替代先前的样本。

其它类型，如结构体、序列和数组不能直接用来做key，但是当结构体的成员或数组中的元素是数值型、枚举型或者字符串型时可以。

## 2、IDL编译：

IDL文件首先需要由tao_idl编译，以生成数据在网络上传输时打包解包的代码，该IDL编译器位于$ACE_ROOT/bin/目录下，运行命令如下：
```
tao_idl Demo.idl
```
该命令为每个IDL文件编译生成6个个文件，这6个文件的文件名均由原IDL文件名开头，如下所示：
```
<filename>C.cpp
<filename>C.h
<filename>C.inl
<filename>S.cpp
<filename>S.h
<filename>S.inl
```
进而，IDL文件还需要由opendds_idl编译，以生成OpenDDS需要打包和解包信息的序列化和键支持代码，及用于数据读者和写者类型支持代码，该IDL编译器位于$DDS_ROOT/bin/目录下，运行命令如下：
```
opendds_idl Demo.idl
```
该命令为每个IDL文件编译生成三个文件，这三个文件的文件名均由原IDL文件名开头，如下所示：
```
<filename>TypeSupport.idl
<filename>TypeSupportImpl.h
<filename>TypeSupportImpl.cpp
```
会生成DemoTypeSupport.idl、DemoTypeSupportImpl.h和DemoTypeSupportImpl.cpp三个文件，生成的IDL文件中包括了PosTypeSupport, PosDataWriter 和PosDataReader的接口定义，这些特定的DDS类型接口将会在稍后注册数据类型，发布数据样本和接收数据样本时使用，而生成的cpp文件实现了这些接口。

生成的IDL文件还需要和原始的IDL一起，由tao_idl编译器再次编译，以便生成相应的接口框架，之后这些生成的实现文件需要和使用Pos类型的OpenDDS应用程序源码一起编译链接。

opendds_idl编译器提供了许多选项参数，用于配置代码生成，这些选项参数将在后续章节详细描述。

通常，我们不需要手动直接调用tao_idl或者opendds_idl来编译IDL文件，可以借助编译工具来完成，如果使用ACE的MPC(MakeProjectCreator)工具，通过继承dcps来配置，该过程将会很简单，如下是使用ACE的MPC工具来实现这个工作的步骤：

首先，需要编写一个Demo.mpc文件，在mpc文件中定义一个idl工程，内容如下：
```
project(*idl): dcps {

    // This project ensures the common components get built first.
    TypeSupport_Files {
        Demo.idl
    }

    custom_only = 1
}
```
idl工程从父工程dcps继承，父工程dcps中定义了类型支持的编译规则，TypeSupport_Files部分告诉MPC，使用opendds_idl编译器从Demo.idl中生成类型支持文件。

编写好mpc文件之后，就可以使用MPC命令来生成C/C++的编译配置文件了，(MPC工具可以生成很多种系统的编译工程，包括Windows的Visual Studio系列，Linux的Makefile等)，这里将Demo.idl文件和Demo.mpc文件放到Demo文件加下，使用如下命令来生成Vs2008的工程：
```
perl mwc.pl -type vc9
```
命令执行完成后，会生成对应的Vs2008工程文件，包括vcproj和sln等，使用Vs2008打开Demo.sln就可以编译前面定义的idl文件，生成DemoC.cpp和DemoTypeSupport.idl等文件了。

关于公布端和订阅端应用程序的开发请参见后续博文。