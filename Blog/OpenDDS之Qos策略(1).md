---
title: OpenDDS之Qos策略(1)
category: OpenDDS
date: 2014-09-16
comments: true
tags:
- OpenDDS
- Qos
- 策略说明
- 策略使用
---

## 简介

OpenDDS对DDS规范（[OMG Document formal/07-01-01](http://www.omg.org/cgi-bin/doc?formal/07-01-01.pdf)）定义的22种QoS策略全部支持。

应用程序通过参与者的QoS约束，来指定需要的行为，然后由DDS的服务决定如何实现这些行为，这些策略应用于所有DDS实体（主题、数据写者、数据读者、发布者、订阅者、域参与者），但不是所有的策略都适用于所有的实体类型。

发布者和订阅者通过RxO模式相匹配，订阅者请求一组策略，发布者提供一组QoS策略给潜在的订阅者，然后DDS试图将请求的策略和提供的策略相匹配，如果这些策略相匹配则将它们关联起来。

在前面的《[基于OpenDDS的应用程序开发](https://lyingbo.github.io/categories/OpenDDS)》博文中，我们采用了默认的QoS策略，接下来的几篇博文将详细介绍每个QoS策略的相关细节。

## Qos策略

每个策略都定义了自己的结构，每个实体都支持策略的一个子集，并且定义了一个由被支持的策略结构体所组成的QoS结构体，一个给定实体的可用策略集不会受到QoS结构体中包含的策略结构体的限制，例如，发布者的QoS结构体的IDL定义格式如下：
```
  module DDS {
   struct PublisherQos {
     PresentationQosPolicy presentation;
     PartitionQosPolicy partition;
     GroupDataQosPolicy group_data;
     EntityFactoryQosPolicy entity_factory;
    };
  };
```
设置一个策略就像获得一个已经有默认值的结构体一样简单，并在必要的时候修改个别策略值，然后将QoS结构体应用到实体中（通常是在实体被建立的时候），后续的章节中将详细说明如何获取各个实体的缺省QoS值。

应用程序可以通过调用set_qos()操作来改变任意实体的QoS策略。如果该QoS策略变得不再兼容，则现有的连接将会移除，否则，如果该Qos策略变得兼容了，将会有新的连接添加。该改变将会通过相应的实体调用QoS更新操作通知DCPSInfoRepo，DCPSInfoRepo将会依据Qos策略规范来重新检测兼容性和关联性，如果兼容性检测失败，set_qos()调用将会返回错误，关联性检测将以移除现有的连接或增加新的连接为结果。

如果试图去改变一个不能改变的QoS策略，set_qos()操作将会返回DDS::RETCODE_IMMUTABLE_POLICY。可以改变的QoS策略有如下几个：USER_DATA,TOPIC_DATA,LIFESPAN,OWNERSHIP_STRENGTH,TIME_BASED_FILTER,ENTITY_FACTORY,WRITER_DATA_LIFECYCLE,READER_DATA_LIFECYCLE，它们不需要重新检测兼容性和关联性。QoS策略DEADLINE和LATENCY_BUDGET需要重新检测相容性，关联性不需要。QoS策略PARTITION恰好相反，只需重新检测关联性，对于兼容性则不需重新检测。

## 默认Qos策略值

应用程序获取实体的默认QoS策略，通过实例化该实体的一个对应的Qos结构体，然后调用实体工厂的get_default_entity_qos()操作将它获取回来（例如，对于发布者和订阅者，可以通过使用域参与者来获取默认QoS）。

下面的示例代码说明了对于发布者、订阅者、主题、域参与者、数据写者、数据读者如何获取默认QoS：
```
// Get default Publisher QoS from a DomainParticipant:
DDS::PublisherQos pub_qos;
DDS::ReturnCode_t ret;
ret = domain_participant->get_default_publisher_qos(pub_qos);
if (DDS::RETCODE_OK != ret) {
  std::cerr << "Could not get default publisher QoS" << std::endl;
}

// Get default Subscriber QoS from a DomainParticipant:
DDS::SubscriberQos sub_qos;
ret = domain_participant->get_default_subscriber_qos(sub_qos);
if (DDS::RETCODE_OK != ret) {
  std::cerr << "Could not get default subscriber QoS" << std::endl;
}

// Get default Topic QoS from a DomainParticipant:
DDS::TopicQos topic_qos;
ret = domain_participant->get_default_topic_qos(topic_qos);
if (DDS::RETCODE_OK != ret) {
  std::cerr << "Could not get default topic QoS" << std::endl;
}

// Get default DomainParticipant QoS from a DomainParticipantFactory:
DDS::DomainParticipantQos dp_qos;
ret = domain_participant_factory->get_default_participant_qos(dp_qos);
if (DDS::RETCODE_OK != ret) {
  std::cerr << "Could not get default participant QoS" << std::endl;
}

// Get default DataWriter QoS from a Publisher:
DDS::DataWriterQos dw_qos;
ret = pub->get_default_datawriter_qos(dw_qos);
if (DDS::RETCODE_OK != ret) {
  std::cerr << "Could not get default data writer QoS" << std::endl;
}

// Get default DataReader QoS from a Subscriber:
DDS::DataReaderQos dr_qos;
ret = pub->get_default_datareader_qos(dr_qos);
if (DDS::RETCODE_OK != ret) {
  std::cerr << "Could not get default data reader QoS" << std::endl;
}
```
下面的表格总结了在OpenDDS中用到的每一种实体类型的默认QoS策略。

表1、默认域参与者QoS策略

策略|成员|默认值
-|:-:|-:
USER_DATA|value|(not set)
ENTITY_FACTORY|autoenable_created_entities|true

表2、默认主题QoS策略

策略|成员|默认值
-|:-:|-:
TOPIC_DATA|value|(not set)
DURABILITY|kind|VOLATILE_DURABILITY_QOS
DURABILITY_SERVICE|service_cleanup_delay.sec|DURATION_ZERO_SEC
DURABILITY_SERVICE|service_cleanup_delay.nanosec|DURATION_ZERO_NSEC
DURABILITY_SERVICE|history_kind|KEEP_LAST_HISTORY_QOS
DURABILITY_SERVICE|history_depth|1
DURABILITY_SERVICE|max_samples|LENGTH_UNLIMITED
DURABILITY_SERVICE|max_instances|LENGTH_UNLIMITED
DURABILITY_SERVICE|max_samples_per_instance|LENGTH_UNLIMITED
DEADLINE|period.sec|DURATION_INFINITY_SEC
DEADLINE|period.nanosec|DURATION_INFINITY_NSEC
LATENCY_BUDGET|duration.sec|DURATION_ZERO_SEC
LATENCY_BUDGET|duration.nanosec|DURATION_ZERO_NSEC
LIVELINESS|kind|AUTOMATIC_LIVELINESS_QOS
LIVELINESS|lease_duration.sec|DURATION_INFINITY_SEC
LIVELINESS|lease_duration.nanosec|DURATION_INFINITY_NSEC
RELIABILITY|kind|BEST_EFFORT_RELIABILITY_QOS
RELIABILITY|max_blocking_time.sec|DURATION_INFINITY_SEC
RELIABILITY|max_blocking_time.nanosec|DURATION_INFINITY_NSEC
DESTINATION_ORDER|kind|BY_RECEPTION_TIMESTAMP_DESTINATIONORDER_QOS
HISTORY|kind|KEEP_LAST_HISTORY_QOS
HISTORY|depth|1
RESOURCE_LIMITS|max_samples|LENGTH_UNLIMITED
RESOURCE_LIMITS|max_instances|LENGTH_UNLIMITED
RESOURCE_LIMITS|max_samples_per_instance|LENGTH_UNLIMITED
TRANSPORT_PRIORITY|value|0
LIFESPAN|duration.sec|DURATION_INFINITY_SEC
LIFESPAN|duration.nanosec|DURATION_INFINITY_NSEC
OWNERSHIP|kind|SHARED_OWNERSHIP_QOS

表3、默认发布者QoS策略

策略|成员|默认值
-|:-:|-:
PRESENTATION|access_scope|INSTANCE_PRESENTATION_QOS
PRESENTATION|coherent_access|0
PRESENTATION|ordered_access|0
PARTITION|name|(empty sequence)
GROUP_DATA|value|(not set)
ENTITY_FACTORY|autoenable_created_entities|true

表4、默认订阅者QoS策略

策略|成员|默认值
-|:-:|-:
PRESENTATION|access_scope|INSTANCE_PRESENTATION_QOS
PRESENTATION|coherent_access|0
PRESENTATION|ordered_access|0
PARTITION|name|(empty sequence)
GROUP_DATA|value|(not set)
ENTITY_FACTORY|autoenable_created_entities|true

表5、默认数据写者QoS策略

策略|成员|默认值
-|:-:|-:
DESTINATION_ORDER|kind|BY_RECEPTION_TIMESTAMP_DESTINATIONORDER_QOS
HISTORY|kind|KEEP_LAST_HISTORY_QOS
HISTORY|depth|1
RESOURCE_LIMITS|max_samples|LENGTH_UNLIMITED
RESOURCE_LIMITS|max_instances|LENGTH_UNLIMITED
RESOURCE_LIMITS|max_samples_per_instance|LENGTH_UNLIMITED
TRANSPORT_PRIORITY|value|0
LIFESPAN|duration.sec|DURATION_INFINITY_SEC
LIFESPAN|duration.nanosec|DURATION_INFINITY_NSEC
USER_DATA|value|(not set)
OWNERSHIP|kind|SHARED_OWNERSHIP_QOS
OWNERSHIP_STRENGTH|value|0
WRITER_DATA_LIFECYCLE|autodispose_unregistered_instances|1
DURABILITY|kind|VOLATILE_DURABILITY_QOS
DURABILITY_SERVICE|service_cleanup_delay.sec|DURATION_ZERO_SEC
DURABILITY_SERVICE|service_cleanup_delay.nanosec|DURATION_ZERO_NSEC
DURABILITY_SERVICE|history_kind|KEEP_LAST_HISTORY_QOS
DURABILITY_SERVICE|history_depth|1
DURABILITY_SERVICE|max_samples|LENGTH_UNLIMITED
DURABILITY_SERVICE|max_instances|LENGTH_UNLIMITED
DURABILITY_SERVICE|max_samples_per_instance|LENGTH_UNLIMITED
DEADLINE|period.sec|DURATION_INFINITY_SEC
DEADLINE|period.nanosec|DURATION_INFINITY_NSEC
LATENCY_BUDGET|duration.sec|DURATION_ZERO_SEC
LATENCY_BUDGET|duration.nanosec|DURATION_ZERO_NSEC
LIVELINESS|kind|AUTOMATIC_LIVELINESS_QOS
LIVELINESS|lease_duration.sec|DURATION_INFINITY_SEC
LIVELINESS|lease_duration.nanosec|DURATION_INFINITY_NSEC
RELIABILITY|kind|RELIABLE_RELIABILITY_QOS
RELIABILITY|max_blocking_time.sec|0
RELIABILITY|max_blocking_time.nanosec|100000000 (100 ms)

表6、默认数据读者QoS策略

策略|成员|默认值
-|:-:|-:
DURABILITY|kind|VOLATILE_DURABILITY_QOS
DEADLINE|period.sec|DURATION_INFINITY_SEC
DEADLINE|period.nanosec|DURATION_INFINITY_NSEC
LATENCY_BUDGET|duration.sec|DURATION_ZERO_SEC
LATENCY_BUDGET|duration.nanosec|DURATION_ZERO_NSEC
LIVELINESS|kind|AUTOMATIC_LIVELINESS_QOS
LIVELINESS|lease_duration.sec|DURATION_INFINITY_SEC
LIVELINESS|lease_duration.nanosec|DURATION_INFINITY_NSEC
RELIABILITY|kind|BEST_EFFORT_RELIABILITY_QOS
RELIABILITY|max_blocking_time.sec|DURATION_INFINITY_SEC
RELIABILITY|max_blocking_time.nanosec|DURATION_INFINITY_NSEC
DESTINATION_ORDER|kind|BY_RECEPTION_TIMESTAMP_DESTINATIONORDER_QOS
HISTORY|kind|KEEP_LAST_HISTORY_QOS
HISTORY|depth|1
RESOURCE_LIMITS|max_samples|LENGTH_UNLIMITED
RESOURCE_LIMITS|max_instances|LENGTH_UNLIMITED
RESOURCE_LIMITS|max_samples_per_instance|LENGTH_UNLIMITED
USER_DATA|value|(not set)
OWNERSHIP|kind|SHARED_OWNERSHIP_QOS
TIME_BASED_FILTER|minimum_separation.sec|DURATION_ZERO_SEC
TIME_BASED_FILTER|minimum_separation.nanosec|DURATION_ZERO_NSEC
READER_DATA_LIFECYCLE|autopurge_nowriter_samples_delay.sec|DURATION_INFINITY_SEC
READER_DATA_LIFECYCLE|autopurge_nowriter_samples_delay.nanosec|DURATION_INFINITY_NSEC
READER_DATA_LIFECYCLE|autopurge_disposed_samples_delay.sec|DURATION_INFINITY_SEC
READER_DATA_LIFECYCLE|autopurge_disposed_samples_delay.nanosec|DURATION_INFINITY_NSEC

有关OpenDDS的相关问题欢迎发送邮件至lyingbo@aliyun.com一起讨论
