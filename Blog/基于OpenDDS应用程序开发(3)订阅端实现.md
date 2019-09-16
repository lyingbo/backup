---
title: 基于OpenDDS应用程序开发(3)订阅端实现
category: OpenDDS
date: 2014-07-29
---

连续的三篇博文演示如何基于OpenDDS开发应用程序，将数据从发布端节点发送到订阅端节点，该示例程序由一个发布者发布数据，一个订阅者订阅数据，使用默认的QoS策略和TCP/IP传输方式。

本文是第三篇，主要介绍开发一个简单的OpenDDS订阅端应用程序所涉及的步骤。省略一些不重要部分(如:#include部分和异常处理等)代码，只写出关键代码。

## 1、新建订阅端工程：

参考前一博文中MPC的用法，在Demo.mpc文件中增加如下内容：
```
 project(*Subscriber) : dcpsexe_with_tcp {

 exename = subscriber
 after += *idl

 TypeSupport_Files {
   Demo.idl
 }

 Source_Files {
   Subscriber.cpp
   DataReaderListenerImpl.cpp
 }
}
```
Subscriber工程从父工程dcpsexe_with_tcp继承，这里直接使用idl工程中定义好的Demo.idl文件。

之后在Demo目录下新建三个文件：Subscriber.cpp、DataReaderListenerImpl.h、DataReaderListenerImpl.cpp，分别用来编写订阅端逻辑部分代码，并再次使用如下命令来生成Vs2008工程：
```
mwc.pl -type vc9
```
生成完成之后，使用Vs2008打开Demo.sln，就可以修改订阅端代码了：

## 2、初始化参与者：

初始化订阅端参与者代码同发布端是完全一样的，在Subscriber.cpp文件中增加如下内容：
```
int main(int argc, char *argv[])
{
  try {
  
   DDS::DomainParticipantFactory_var dpf =
     TheParticipantFactoryWithArgs(argc, argv);

   DDS::DomainParticipant_var participant =
     dpf->create_participant(42, // Domain ID
                         PARTICIPANT_QOS_DEFAULT,
                         0,  // No listener required
                         OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!participant) {
     std::cerr << "create_participant failed." << std::endl;
     return 1 ;
   }
```
## 3、注册数据类型并创建主题：

接下来，初始化数据类型和主题：
```
   Demo::PosTypeSupport_var mts = new Demo::PosTypeSupportImpl();
   if (DDS::RETCODE_OK != mts->register_type(participant, "")) {
     std::cerr << "Failed to register the PosTypeSupport." << std::endl;
     return 1;
   }

   CORBA::String_var type_name = mts->get_type_name();
   DDS::Topic_var topic =
     participant->create_topic("Pos Demo",
                           type_name,
                           TOPIC_QOS_DEFAULT,
                           0,   // No listener required
                           OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!topic) {
     std::cerr << "Failed to create_topic." << std::endl;
     return 1;
   }
```
## 4、创建订阅者：

调用create_subscriber()操作创建一个带有默认QoS策略的订阅者：
```
   DDS::Subscriber_var sub =
     participant->create_subscriber(SUBSCRIBER_QOS_DEFAULT,
                               0,  // No listener required
                               OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!sub) {
     std::cerr << "Failed to create_subscriber." << std::endl;
     return 1;
   }
```
## 5、创建数据读者及监听者：

订阅端需要给数据读者关联一个监听者，用来接收数据的到达，下面的代码定义了一个监听者对象，类DataReaderListenerImpl的实现将在下一部分介绍。
```
 DDS::DataReaderListener_var listener(new DataReaderListenerImpl);
```
现在采用默认的QoS策略创建数据读者，并将它与主题、刚刚创建的监听者对象相关联起来：
```
   DDS::DataReader_var dr =
     sub->create_datareader(topic,
                        DATAREADER_QOS_DEFAULT,
                        listener,
                        OpenDDS::DCPS::DEFAULT_STATUS_MASK);
   if (!dr) {
     std::cerr << "create_datareader failed." << std::endl;
     return 1;
   }
```
之后，主线程就可以自由的去处理其它工作了，当有数据到达时，OpenDDS会调用监听者对象的回调接口通知，只需要在DataReaderListenerImpl类的回调函数中接收需要的数据就可以了。

## 6、数据读者监听者实现：

监听者类继承自DDS规范的DDS::DataReaderListener接口，该接口定义了一些回调函数，每个回调函数被调用时，就是一个事件的通知，如：断开、重连等，以下是DataReaderListener接口的定义：
```
module DDS {

 local interface DataReaderListener : Listener {

   void on_requested_deadline_missed(in DataReader reader,
                                 in RequestedDeadlineMissedStatus status);

   void on_requested_incompatible_qos(in DataReader reader,
                                 in RequestedIncompatibleQosStatus status);

   void on_sample_rejected(in DataReader reader,
                        in SampleRejectedStatus status);

   void on_liveliness_changed(in DataReader reader,
                          in LivelinessChangedStatus status);

   void on_data_available(in DataReader reader);

   void on_subscription_matched(in DataReader reader,
                            in SubscriptionMatchedStatus status);

   void on_sample_lost(in DataReader reader, in SampleLostStatus status);

 };
};
```
在本例的DataReaderListenerImpl类中真正需要的实现的回调接口是on_data_available()，它也是我们需要重新派生该类的唯一成员函数：
```
void DataReaderListenerImpl::on_data_available(DDS::DataReader_ptr reader) {

 num_reads_ ++;

 try{

   Demo::PosDataReader_var reader_i = Demo::PosDataReader::_narrow(reader);
   if (!reader_i) {
     std::cerr << "read: _narrow failed." << std::endl;
     return;
   }

   Demo::Pos pos;
   DDS::SampleInfo si ;
   DDS::ReturnCode_t status = reader_i->take_next_sample(pos, si) ;
   if (status == DDS::RETCODE_OK) {
   
     if (si.valid_data == 1) {
       std::cout << " Pos:pos_id = " << pos. pos_id << std::endl
                 << "  pos_x = " << pos. pos_x << std::endl
                 << "  pos_y = " << pos. pos_y << std::endl;
     } else if (si.instance_state == DDS::NOT_ALIVE_DISPOSED_INSTANCE_STATE) {
       std::cout << "instance is disposed" << std::endl;
     } else if (si.instance_state == DDS::NOT_ALIVE_NO_WRITERS_INSTANCE_STATE) {
       std::cout << "instance is unregistered" << std::endl;
     } else {
       std::cerr << "ERROR: received unknown instance state "
               << si.instance_state << std::endl;
     }
	 
   } else if (status == DDS::RETCODE_NO_DATA) {
       cerr << "ERROR: reader received DDS::RETCODE_NO_DATA!" << std::endl;
   } else {
       cerr << "ERROR: read Pos: " << status << std::endl;
   }
```
上面的代码将样本从数据读者中取出，如果成功并能返回有效数据，就打印出接收到数据的每一个字段。

每当有样本数据到达时，该函数就会被调用。

## 7、实体清理：

在订阅完数据以后，需要清理与OpenDDS相关联的资源：
```
  participant->delete_contained_entities();
  dpf->delete_participant(participant);
  TheServiceParticipant->shutdown();
```
调用域参与者的delete_contained_entities()操作删除所有该参与者创建的主题、订阅者。一旦执行完该操作，就可以使用域参与者工厂删除域参与者了。

## 8、示例程序运行：

修改完以上代码并编译完成，就可以运行订阅端应用程序了，需要先运行DDS的信息仓库，开始中打开一个CMD窗口，执行如下命令：
```
%DDS_ROOT%/bin/DCPSInfoRepo -ORBEndpoint iiop://localhost:12345
```
再次打开一个CMD窗口，cd到Demo目录下，执行如下命令：
```
subscriber -DCPSInfoRepo corbaloc::localhost:12345/DCPSInfoRepo
```
至此，订阅端应用程序就开发完成并运行起来了。