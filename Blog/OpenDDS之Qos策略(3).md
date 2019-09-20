---
title: OpenDDS之Qos策略(3)
category: OpenDDS
date: 2016-03-20
comments: true
tags:
- OpenDDS
- Qos
- 策略说明
- 策略使用
---

OpenDDS主要支持22种Qos，前一篇[OpenDDS之Qos策略(2)](https://lyingbo.github.io/2015/11/23/OpenDDS%E4%B9%8BQos%E7%AD%96%E7%95%A5(2))已对前12种Qos的具体内容作了介绍，接下来介绍下这剩下的10种Qos的具体内容以及用法。

## 13、TRANSPORT_PRIORITY
TRANSPORT_PRIORITY策略主要应用于主题和数据写者实体，下面是TRANSPORT_PRIORITY QoS策略的IDL：
```
struct TransportPriorityQosPolicy {
  long value;
};
```
value的默认值是0。该策略用于指定传输层发送消息时采用的优先级，值越大，表示优先级越高。OpenDDS把优先级映射到线程的优先级和DiffServ码点值上。默认值为0表示发送消息时既不修改线程的优先级，也不修改DiffServ的码点值。

OpenDDS支持设置发送线程的传输优先级和接收线程的传输优先级。传输优先级从0到最大值线性地映射0（默认）到最大线程优先级。如果最低传输优先级不是0，也映射为线程的优先级0。如果优先级在系统上出现倒置（数值越大优先级越低），OpenDDS将从0开始的增加的优先级。优先级比最低优先级还小则映射为最低优先级；如果高于线程最大优先级，则映射为最高优先级。

在大部分操作系统中，只有进程调度器设置为允许时，才能修改线程的优先级。进程需要获得系统特权才能执行相应操作，在基于POSIX的系统中，系统调用sched_get_priority_min()和sched_get_priority_max()来检测系统的线程优先级范围。

在传输层支持的前提下，OpenDDS将试图设置数据写者用来发送数据的套接字的DiffServ码点值。如果网络硬件支持码点值，越高的码点将具有越高的优先级，默认值0映射为码点值0（默认的）。优先级值从1到63会映射为相应的码点值，更高的取值都映射为最高值值63。OpenDDS当前版本不支持在创建数据写者之后修改transport_priority策略值。

## 14、LATENCY_BUDGET
LATENCY_BUDGET策略主要应用于主题，数据读者和数据写者实体，下面是LATENCY_BUDGET QoS策略的IDL：
```
struct LatencyBudgetQosPolicy {
  Duration_t duration;
};
```
成员duration的默认值是0，表示延迟尽量小。该策略用来指示传输层发送样本的紧急程度。OpenDDS使用该值划分样本从发布者到订阅者之间的传输时间是否为不可接受的延迟间隔。目前，该策略仅适用于监视目的，若需要调节传输延迟可使用TRANSPORT_PRIORITY策略。数据写者仅使用duration做兼容性比较，如果该值为默认的0，所有向它请求的数据读者都认为是兼容的。

为了统计超过duration策略设置的延迟数据，额外增加了一个监听者扩展接口。OpenDDS::DCPS::DataReaderListener额外提供了一个通知操作，当样本接收后测量的传输时延大于LATENCY_BUDGET策略的duration时，将会触发该操作，下面是该操作方法的IDL：
```
struct BudgetExceededStatus {
  long total_count;
  long total_count_change;
  DDS::InstanceHandle_t last_instance_handle;
};

void on_budget_exceeded{
  in DDS::DataReader reader,
  in BudgetExceededStatus status
};
```
要使用扩展的Listener回调，首先要从Listener实现中派生一个类，如下面代码段所示：
```
class DataReaderListenerImpl
   : public virtual
   OpenDDS::DCPS::LocalObject
```
接下来需要为on_budget_exceeded()操作提供一个非空的实现。需要注意的是，还需要为下面的扩展操作至少也提供一个空的实现：
```
on_subscription_disconnected()
on_subscription_reconnected()
on_subscription_lost()
on_connection_deleted()
```
OpenDDS还通过数据读者的扩展接口，提供了延迟统计汇总的功能，该扩展接口在OpenDDS::DCPS模型中，其IDL定义如下：
```
struct LatencyStatistics {
  GUID_t publication;
  unsigned long n;
  double maximum;
  double minimum;
  double mean;
  double variance;
};

typedef sequence LatencyStatisticsSeq;

local interface DataReaderEx : DDS::DataReader {

  // Obtain a sequence of statistics summaries.
  void get_latency_stats( inout LatencyStatisticsSeq stats);

  // Clear any intermediate statistical values.
  void reset_latency_stats();

  // Statistics gathering enable state.
  attribute boolean statistics_enabled;

};
```
为了活的统计信息，需要使用上述扩展接口。也可以通过对数据读者对象的指针类型做转换，然后直接调用相应的接口。参见下面的示例代码，假定reader已经通过调用create_datareader方法正确初始化了：
```
  DDS::DataReader_var reader = DDS::Subscriber::create_datareader();

  // ...
  // To start collecting new data.
  dynamic_cast(reader.in())->reset_latency_stats();
  dynamic_cast(reader.in())->statistics_enabled(true);

  // ...
  // To collect data.
  OpenDDS::DCPS::LatencyStatisticsSeq stats;
  dynamic_cast(reader.in())->get_latency_stats(stats);

  for (unsigned long i = 0; i < stats.length(); ++i) {
    std::cout << "stats[" << i << "]:" << std::endl;
    std::cout << " n = " << stats[i].n << std::endl;
    std::cout << " max = " << stats[i].maximum << std::endl;
    std::cout << " min = " << stats[i].minimum << std::endl;
    std::cout << " mean = " << stats[i].mean << std::endl;
    std::cout << " variance = " << stats[i].variance << std::endl;
  }
```
## 15、ENTITY_FACTORY
ENTITY_FACTORY策略控制实体创建时，是否可以自动激活，下面是关于ENTITY_FACTORY QoS策略的IDL：
```
struct EntityFactoryQosPolicy {
  boolean autoenable_created_entities;
};
```
该策略可以应用到像工厂一样为其其它实体服务的实体，并且控制这些被工厂创建的实体是否自动激活。该策略可以应用于域参与者工厂（域参与者的工厂）、域参与者（发布者，订阅者，主题的工厂）、发布者（数据写者的工厂）、订阅者（数据读者的工厂）。该策略的默认值是true，表示工厂实体创建的其它实体可自动激活。如果应用程序希望这些实体可以在需要的时候才激活，可以把该策略的autoenable_created_entities成员的值设为false，然后手动调用实体的enable()操作来手动激活该实体。

该策略的值可以在运行的时候修改，改变将只会影响那些在之后被创建的实体。

## 16、PRESENTATION
PRESENTATION QoS策略控制当订阅者具有一组读者时数据样本的展示顺序。它将影响实例的变化和一定范围内实例的展示顺序。另外，该策略还引入了连续变化集合的概念，下面是PRESENTATION QoS的IDL：
```
enum PresentationQosPolicyAccessScopeKind {
  INSTANCE_PRESENTATION_QOS,
  TOPIC_PRESENTATION_QOS,
  GROUP_PRESENTATION_QOS
};

struct PresentationQosPolicy {
  PresentationQosPolicyAccessScopeKind access_scope;
  boolean coherent_access;
  boolean ordered_access;
};
```
实例改变的范围指的是在应用程序中可能涉及到的级别，分为以下几个：
* INSTANCE_PRESENTATION_QOS（默认值）表示实例变化之间是无关的。尽管可以设置coherent_access（连续访问）和ordered_access（顺序访问），但代表相应的操作为空，也就是说，设为这个级别后对订阅者没有影响。
* TOPIC_PRESENTATION_QOS表示获取的实例变化只限于相同的读者或写者。
* GROUP_PRESENTATION_QOS表示获取的实例变化限制在相同发布者或订阅者上的所有实例。

coherent_access允许在一个实例上的一个或者多个改变关联合并为一个单个变化。如果数据读者没能完整的接收到所有的改变，那么相当于这些改变都是无效的。这个语义非常类似于传统关系数据库的事件处理。coherent_access的默认值为false。

ordered_access表示发布者发布的数据在读者上按顺序展示。它的效果在本质上和DESTINATION_ORDER策略很相似，不同的是，ordered_access允许数据的顺序与实例顺利无关。ordered_access的默认值为false。

注：该策略影响了订阅者获得样本的顺序和作用域，但是订阅端应用程序必须使用合适的逻辑来读取这些样本以保证请求的行为。

## 17、DESTINATION_ORDER
DESTINATION_ORDER QoS策略控制数据实例的样本到达数据读者的顺序，如果HISTRORY策略的depth成员变量设为默认值1，实际将影响写者所写的所有最新数据样本，下面是DESTINATION_ORDER Qos的IDL：
```
enum DestinationOrderQosPolicyKind {
  BY_RECEPTION_TIMESTAMP_DESTINATIONORDER_QOS,
  BY_SOURCE_TIMESTAMP_DESTINATIONORDER_QOS
};

struct DestinationOrderQosPolicy {
  DestinationOrderQosPolicyKind kind;
};
```
* 值BY_RECEPTION_TIMESTAMP_DESTINATIONORDER_QOS（默认）表示读者接收到的实例的样本按接收端的时间排序。值得注意的是，对于同一个写者发出的数据样本，接收方未必按顺序接收。如果需要强制按顺序接收，另一种方式BY_SOURCE_TIMESTAMP_DESTINATIONORDER_QOS值将会用到。
* 值BY_SOURCE_TIMESTAMP_DESTINATIONORDER_QOS表示数据实例的样本按发出的写者端的时间排序。需要注意的是，如果多个数据写者写相同的实例，必须保证多个写者所在的主机时钟同步。

## 18、WRITER_DATA_LIFECYCLE
WRITER_DATA_LIFECYCLE QoS策略控制数据写者管理的数据实例集合，下面是WRITER_DATA_LIFECYCLE QoS策略的IDL：
```
struct WriterDataLifecycleQosPolicy {
  boolean autodispose_unregistered_instances;
};
```
当成员autodispose_unregistered_instances设为true时（默认），数据写者在实例注销时自动清除。在有的情况下，当实例注销时，这是一个不错的实例保护方式。比如，该策略允许EXCLUSIVE（独占）式的数据写者优雅地遵从后续的读者而不影响实例的状态，删除一个数据写者会隐含的注销读者保存的先前的所有样本。

## 19、READER_DATA_LIFECYCLE
READER_DATA_LIFECYCLE QoS策略控制数据读者管理的数据实例集合，下面是READER_DATA_LIFECYCLE QoS策略的IDL：
```
struct ReaderDataLifecycleQosPolicy {
  Duration_t autopurge_nowriter_samples_delay;
  Duration_t autopurge_disposed_samples_delay;
};
```
通常，数据读者保存实例的样本直到与该样本没有任何关联的写者为止，实例已经被处理，实例要么被清除，要么被应用程序读取。

在有些情况下，由于资源的使用问题，需要有合理的约束方式。例如，在故障切换的环境中，该策略允许晚加入的数据写者延长实例的生命周期。

成员autopurge_nowriter_samples_delay可控制读者在资源回收之前所要等待的时间，实例的状态转移为NOT_ALIVE_NO_WRITERS，该成员的默认值为无穷大。

成员autopurge_disposed_samples_delay可控制读者在资源回收之前所要等待的时间，实例的状态转移为NO_ALIVE_DISPOSED，该成员的默认值为无穷大。

## 20、TIME_BASED_FILTER
TIME_BASED_FILTER QoS策略可以用于指定接收者多长时间接收数据。对于不同的数据样本，不管发布者以多快的速度发布数据，在订阅端，都可以指定数据实例接收更新样本的最小间隔时间，下面是TIME_BASED_FILTER QoS策略的IDL：
```
struct TimeBasedFilterQosPolicy{
  Duration_t minimum_separation;
};
```
数据读者可以指定一个时间间隔（minimum_separation），该间隔指定了实例更新的的最小时间间隔；它允许数据读者在不影响关联的数据写者状态的前提下，可以修改。默认的minimum_separation是0，表示没有间隔。该QoS策略不会节省带宽，实例值的更新仍然会发送给订阅者进程，它只会影响那些数据读者获取的样本。

## 21、OWNERSHIP
OWNERSHIP策略控制是否允许多个数据写者为同一个实例发布样本。所有权可以为EXCLUSIVE和SHARED方式，下面是OWNERSHIP QoS策略IDL：
```
enum OwnershipQosPolicyKind {
  SHARED_OWNERSHIP_QOS,
  EXCLUSIVE_OWNERSHIP_QOS
};

struct OwnershipQosPolicy {
  OwnershipQosPolicyKind kind;
};
```
kind成员设为共享方式SHARED_OWNERSHIP_QOS，表示允许多个数据写者更新同一个数据实例。如果kind成员设置为独占式EXCLUSIVE_OWNERSHIP_QOS，表示只允许具有实例所有权的数据写者更新实例。实例的所有者是由OWNERSHIP_STRENGTH策略决定的；OWNERSHIP_STRENGTH策略中成员变量value取值最大的数据写者为实例的所有者。影响所有权还有一个可能的因素，具有最高值的写者是否还存活着，这个由LIVELINESS策略决定。

## 22、OWNERSHIP_STRENGTH
OWNERSHIP_STRENGTH策略与OWNERSHI策略配合使用，当OWNERSHI的kind设为独占式EXCLUSIVE时有效，下面是OWNERSHIP_STRENGTH QoS策略的IDL：
```
struct OwnershipStrengthQosPolicy {
  long value;
};
```
value成员变量用来确定数据写者是否是数据实例的所有权者，它的默认值为0。

## 策略使用示例
下面的示例代码演示了Qos策略在发布端的应用：
```
DDS::DataWriterQos dw_qos;
pub->get_default_datawriter_qos(dw_qos);

dw_qos.history.kind = DDS::KEEP_ALL_HISTORY_QOS;
dw_qos.reliability.kind = DDS::RELIABLE_RELIABILITY_QOS;
dw_qos.reliability.max_blocking_time.sec = 10;
dw_qos.reliability.max_blocking_time.nanosec = 0;
dw_qos.resource_limits.max_samples_per_instance = 100;

DDS::DataWriter_var dw =
  pub->create_datawriter(topic, dw_qos, 0, // No listener
                     OpenDDS::DCPS::DEFAULT_STATUS_MASK);
```
上述代码创建了发布端的数据写者，试用了以下几种Qos策略：
* HISTORY 策略，取值为保持所有；
* REALIBAILITY 策略，设置可靠类型的最大阻塞时间为10秒；
* RESOURCE_LIMIT策略，设置每个实例的的最大样本数为100。

以上策略的组合意味着：当100个样本等待传送时，写者在返回错误码前可以阻塞多达10秒。如果相同的策略应用在数据读者上，置意味着：直至有100个未读的样本排队之后，允许有样本被拒收。被拒绝的样本会被丢弃掉，并更新SampleRejectStatus(样本拒收状态)。

有关OpenDDS的相关问题欢迎发送邮件至lyingbo@aliyun.com一起讨论
