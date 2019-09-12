---
title: 基于OpenDDS应用程序开发(2)公布端实现
category: OpenDDS
date: 2019-08-27
---

连续的三篇博文演示如何基于OpenDDS开发应用程序，将数据从发布端节点发送到订阅端节点，该示例程序由一个发布者发布数据，一个订阅者订阅数据，使用默认的QoS策略和TCP/IP传输方式。

本文是第二篇，主要介绍开发一个简单的OpenDDS公布端应用程序所涉及的步骤，省略一些不重要部分(如:#include部分和异常处理等)代码，只写出关键代码。

## 新建公布端工程

参考前一博文中MPC的用法，在Demo.mpc文件中增加如下内容：
```
project(*Publisher) : dcpsexe_with_tcp {

 exename   = publisher
 after   += *idl

 TypeSupport_Files {
   Demo.idl
 }

 Source_Files {
   Publisher.cpp
 }
}
```
Publisher工程从父工程dcpsexe_with_tcp继承，这里直接使用idl工程中定义好的Demo.idl文件，之后在Demo目录下新建一个Publisher.cpp文件，用来编写公布端逻辑部分代码，并再次使用如下命令来生成Vs2008工程：
```
mwc.pl  -type  vc9
```
生成完成之后，使用Vs2008打开Demo.sln就可以修改Publisher.cpp中的代码了：

## 初始化参与者

main()函数的第一部分是为当前进程初始化一个OpenDDS参与者。
```
int main (int argc, char *argv[]) {

  try {

   DDS::DomainParticipantFactory_var dpf =
     TheParticipantFactoryWithArgs(argc, argv);

   DDS::DomainParticipant_var participant =
     dpf->create_participant(42, // domain ID
                         PARTICIPANT_QOS_DEFAULT,
                          0,  // No listener required
                          OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!participant) {
     std::cerr << "create_participant failed." << std::endl;
     return 1;
   }
```
调用宏TheParticipantFactoryWithArgs，使用命令行参数初始化参与者工厂，这些命令行参数用来初始化ORB服务。

调用create_participant()操作，使用默认的QoS策略，在域参与者工厂中注册一个域参与者，并指定域ID为42，使用DDS默认的状态掩码，确保所有在中间件中的相关通信状态改变都能传递到应用程序中，域ID可以是在0x0~0x7FFFFFFF范围内的任意值，返回域参与者对象的引用，用来注册待公布的数据类型。

## 注册数据类型并创建主题

首先，new一个PosTypeSupportImpl对象，然后调用register_type()操作注册一个带有类型名称的类型，示例中，使用空的类型名称，DDS缺省会把PosTypeSupport接口标识符作为该类型的名称，当然，也可以使用像“Pos”这样的特定类型名称。
```
  Demo::PosTypeSupport_var mts = new Demo::PosTypeSupportImpl();
  if (DDS::RETCODE_OK != mts->register_type(participant, "")) {
   std::cerr << "register_type failed." << std::endl;
   return 1;
 }
```
接下来，从类型支持对象中获得注册的类型名称，调用create_topic()操作来创建主题。
```
   CORBA::String_var type_name = mts->get_type_name();

   DDS::Topic_var topic =
   participant->create_topic ("Pos Demo",
                           type_name,
                           TOPIC_QOS_DEFAULT,
                           0,   // No listener required
                           OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!topic) {
     std::cerr << "create_topic failed." << std::endl;
     return 1;
   }
```
如上代码所示，创建了一个名称为“Pos Demo”，默认主题类型和默认QoS策略的主题，接下来再创建公布者。

## 创建公布者

调用create_publisher()操作创建一个带有默认公布者QoS策略的公布者。
```
   DDS::Publisher_var pub =
     participant->create_publisher(PUBLISHER_QOS_DEFAULT,
                              0,   // No listener required
                              OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!pub) {
     std::cerr << "create_publisher failed." << std::endl;
     return 1;
   }
```
## 创建数据写者

有了公布者，再调用create_datawriter()操作创建一个数据写者。
```
   DDS::DataWriter_var writer =
     pub->create_datawriter(topic,
                        DATAWRITER_QOS_DEFAULT,
                        0,   // No listener required
                        OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!writer) {
     std::cerr << "create_datawriter failed." << std::endl;
     return 1;
}
```
在创建数据写者的时候，使用已经创建好的主题，默认的QoS 策略和空的监听者。然后将数据写者引用转换为PosDataWriter对象引用，方便使用数据写者类中已经定义好的接口。
```
Demo::PosDataWriter_var pos_writer = Demo::PosDataWriter::_narrow(writer);
```
## 公布数据

创建好数据写者，就可以公布数据了，先初始化要公布的对象pos的各个字段，之后调用数据写者的write接口公布数据：
```
   Demo::Pos pos;
   pos.pos_id = 99;
   pos. pos_x = 99;
   pos. pos_y = 99;
   for (int i = 0; i < 10; ++i) {
     DDS::ReturnCode_t error = pos_writer->write(pos, DDS::HANDLE_NIL);
     ++pos.pos_id;
     if (error != DDS::RETCODE_OK) {
       // Log or otherwise handle the error condition
       return 1;
     }
   }
```
对于每个循环，调用write()操作将样本数据发送给所有注册过该主题的订阅者。

## 等待接收

由于DDS中的数据公布和数据订阅是解耦的，数据不保证一定交付。如果公布端应用程序要求所有公布的数据必须全部交付，需要在公布端调用数据写者的wait_for_acknowledgements()操作，来使公布端应用程序一直等待，直到订阅端接收到所有已经公布的数据。要使wait_for_acknowledgements()操作有效，数据读者必须设置RELIABILITY QoS策略（是缺省值）为RELIABLE。

数据写者调用此操作，并绑定一个timeout值作为等待的超时时间。如下的代码演示了调用wait_for_acknowledgements()阻塞15s等待订阅端接收所有数据的方法：
```
DDS::Duration_t shutdown_delay = {15, 0};

  DDS::ReturnCode_t result;
  result = writer->wait_for_acknowledgments(shutdown_delay);
  if( result != DDS::RETCODE_OK) {
   std::cerr << "Failed while waiting for acknowledgment of "
             << "data being received by subscriptions, some data "
             << "may not have been delivered." << std::endl;
 }
```
## 实体清理

在公布完数据以后，需要清理与OpenDDS相关联的资源：
```
  participant->delete_contained_entities();
  dpf->delete_participant(participant);
  TheServiceParticipant->shutdown ();
```
调用域参与者的delete_contained_entities()操作删除所有该参与者创建的主题、公布者。一旦执行完该操作，就可以使用域参与者工厂删除域参与者了。

## 示例程序运行

修改完以上代码并编译完成，就可以运行公布端应用程序了，需要先运行DDS的信息仓库，开始中打开一个CMD窗口，执行如下命令：
```
%DDS_ROOT%/bin/DCPSInfoRepo  -ORBEndpoint  iiop://localhost:12345
```
再次打开一个CMD窗口，cd到Demo目录下，执行如下命令：
```
publisher -DCPSInfoRepo  corbaloc::localhost:12345/DCPSInfoRepo
```
至此，公布端应用程序就开发完成并运行起来了。