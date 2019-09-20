---
title: OpenDDS之Qos策略(2)
category: OpenDDS
date: 2015-11-23
comments: true
tags:
- OpenDDS
- Qos
- 策略说明
- 策略使用
---

OpenDDS主要支持22种Qos，前一篇[OpenDDS之Qos策略(1)](https://lyingbo.github.io/2014/09/16/OpenDDS%E4%B9%8BQos%E7%AD%96%E7%95%A5(1))已对Qos整体、以及默认值做了介绍，接下来介绍这22种Qos的具体内容和用法，由于内容较多，分两篇来完成。

## 1、LIVELINESS
LIVELINESS策略主要应用于主题，数据写者，数据读者实体中。在主题中设置该策略，意味着对于所有发布订阅该主题的数据写者、数据读者都是有效的，下面是LIVELINESS QoS策略的IDL：
```
enum LivelinessQosPolicyKind {
  AUTOMATIC_LIVELINESS_QOS,
  MANUAL_BY_PARTICIPANT_LIVELINESS_QOS,
  MANUAL_BY_TOPIC_LIVELINESS_QOS
};

struct LivelinessQosPolicy {
  LivelinessQosPolicyKind kind;
  Duration_t lease_duration;
};
```
LIVELINESS策略控制服务何时以及如何检测参与者是否还存活，存活表示参与者仍然处于可访问和激活状态。kind成员设置检测方式为自动或是实体手动检测，把kind设为AUTOMATIC_LIVELINESS_QOS，表示服务如果在lease_duration时间周期内没有任何网络流量，则自动的发出表示参与者存活的信息。把kind设为MANUAL_BY_PARTICIPANT_LIVELINESS_QOS或者是MANUAL_BY_TOPIC_LIVELINESS_QOS表示实体要在指定的心跳间隔内写入数据样本或者发送确认在线的消息，心跳间隔时间由lease_duration字段指定。lease_duration的默认值为无穷大，表示禁用存活检测。

手动发布存活消息而不发布数据样本，可以在指定的心跳间隔时间内通过调用数据写者或者域参与者的assert_liveliness()操作来实现。

数据写者指定（提供）自己的心跳数据准则，数据读者指定期望的写者的心跳数据。如果没有在心跳间隔期间内收到写者的数据(既没有样本数据，也没有确认存活的消息)，将会触发LIVELINESS_CHANGED_STATUS通信状态改变，并通知应用程序（通过调用数据写者监听者的on_liveliness_changed()回调函数）。

该策略的兼容性是在数据读者和数据写者之间关联关系建立的时候检测的，要建立关联关系，必须保证两端的策略值的兼容性。数据读者需要的策略和数据写者提供的策略的比较值决定了相容性。在决定相容性的时候，两种策略（AUTO、MANUAL）都需要和lease_duration的值相比较。写者提供的策略值必须大于或等于读者需要的策略值。该策略值的排序如下：
```
MANUAL_BY_TOPIC_LIVELINESS_QOS > MANUAL_BY_PARTICIPANT_LIVELINESS_QOS > AUTOMATIC_LIVELINESS_QOS
```
此外，写者提供的lease_duration必须小于或者等于读者的lease_duration。这些情况都必须符合提供、请求策略的兼容性要求，考虑兼容性和关联关系的建立。

## 2、RELIABILITY
RELIABILITY策略主要应用于主题，数据读者，数据写者实体中，下面是RELIABILITY QoS策略的IDL：
```
enum ReliabilityQosPolicyKind {
  BEST_EFFORT_RELIABILITY_QOS,
  RELIABLE_RELIABILITY_QOS
};

struct ReliabilityQosPolicy {
  ReliabilityQosPolicyKind kind;
  Duration_t max_blocking_time;
};
```
该策略控制数据读者处理样本数据的方式。把kind设置为BEST_EFFORT_RELIABILITY_QOS表示数据读写者尽力交付，不保证样本数据的可靠性传输，在某些情况下，允许样本丢弃。把kind设置为RELIABLE_RELIABILITY_QOS表示服务最终把样本传送给合适的数据读者。

当HISTORY QoS策略设置为KEEP_ALL_HISTORY_QOS，并且数据写者在写数据遇到资源限制（因为传输反压，详见6）时，会用到该策略的max_blocking_time字段。当这种情况发生时，数据写者会阻塞，如果阻塞时间超过了max_blocking_time指定的值，再调用写操作就会返回一个写超时的错误码。对于数据读者和主题，该策略的默认值是“BEST_EFFORT，对于数据写者，默认值是RELIABLE。

该策略的兼容性在数据写者和数据读者建立关联关系的时候，就需要考虑。要成功建立关联关系，两边的取值一定要相互兼容。该策略的兼容性要求数据写者的策略值一定要大于或等于数据读者的策略值。

## 3、HISTORY
HISTORY策略指定数据读者和数据写者保留特定实例样本的数量。对于数据写者，这些样本被保存直到发布者取出它们并成功的发送给所有关联的订阅者；对于数据读者，这些样本被保存直到应用程序取出它们。该策略主要应用于主题、数据写者、数据读者实体，下面是HISTORY QoS策略的IDL：
```
enum HistoryQosPolicyKind {
  KEEP_LAST_HISTORY_QOS,
  KEEP_ALL_HISTORY_QOS
};

struct HistoryQosPolicy {
  HistoryQosPolicyKind kind;
  long depth;
};
```
取值KEEP_ALL_HISTORY_QOS表示所有的样本都将保存。当指定KEEP_ALL_HISTORY_QOS并且未读取的样本数量等于资源限制策略所设置的max_samples_per_instance时，之后新到来的样本都将被拒收。取值KEEP_LAST_HISTORY_QOS表示只保存depth条最新样本。当数据写者保存的样本条数已经达到depth时，新写入的样本会被排入待发送队列中，而最早写入的样本将会被丢弃。

该策略的默认值是“KEEP_LAST_HISTORY_QOS”，并且depth为1。

## 4、DURABILITY
DURABILITY策略控制数据写者是否管理已发出的样本。该策略主要应用于主题，数据写者，数据读者实体，下面是DURABILITY QoS策略的IDL：
```
enum DurabilityQosPolicyKind {
  VOLATILE_DURABILITY_QOS,  // Least Durability
  TRANSIENT_LOCAL_DURABILITY_QOS,
  TRANSIENT_DURABILITY_QOS,
  PERSISTENT_DURABILITY_QOS  // Greatest Durability
};

struct DurabilityQosPolicy {
  DurabilityQosPolicyKind kind;
};
```
kind的默认值是VOLATILE_DURABILITY_QOS:
* 为VOLATILE_DURABILITY_QOS表示样本在发送给已知的订阅者之后即丢弃。因此，订阅者不能找回在它与发布者建立连接之前的任何样本。
* 为TRANSIENT_LOCAL_DURABILITY_QOS表示数据读者一旦和数据写者建立连接，写者将发送历史中的所有样本。
* 为TRANSIENT_DURABILITY_QOS表示只要进程没有退出，数据写者的样本就会在内存保留，但不保存在外部存储器中。当同一个域中的数据读者订阅了相同的主题及分区时，写者把所有缓存的样本全部发送出去。
* 为PERSISTENT_DURABILITY_QOS表示除了提供与TRANSIENT_DURABILITY_QOS相同的功能外，还把样本保留在持久的外部存储器中，即便进程退出，样本仍然可以幸存。

一旦该策略被指定为TRANSIENT或PERSISTENT时，需要设置DURABILITY_SERVICE QoS策略调节持久度缓存的参数。

该策略的兼容性需要在数据写者和数据读者之间建立关联关系的时候考虑。要成功建立关联关系，两边的值一定要兼容。要求数据写者的持久性值一定要大于或等于数据读者的值。持久性大小关系如下：
```
PERSISTENT_DURABILITY_QOS > TRANSIENT_DURABILITY_QOS > TRANSIENT_LOCAL_DURABILITY_QOS > VOLATILE_DURABILITY_QOS
```
## 5、DURABILITY_SERVICE
DURABILITY_SERVICE策略控制TRANSIENT 或 PERSISTENT的持久缓存中样本的删除。该策略主要应用于主题，数据写者实体。该策略还提供了一种用于设置HISTORY 和RESOURCE_LIMITS策略关于样本缓冲参数的方式，下面是DURABILITY_SERVICE QoS策略的IDL：
```
struct DurabilityServiceQosPolicy {
  Duration_t             service_cleanup_delay;
  HistoryQosPolicyKind   history_kind;
  long                   history_depth;
  Long                   max_samples;
  long                   max_instances;
  long                   max_samples_per_instance;
};
```
该策略中的字段与HISTORY 和RESOURCE_LIMITS中的成员有些相似，但与它们无关。字段service_cleanup_delay可以按需要设定，默认值为0，表示不删除缓存中的样本。

## 6、RESOURCE_LIMITS
RESOURCE_LIMITS策略指定可以消耗的资源的数量。该策略主要应用于主题，数据写者，数据读者实体，下面是RESOURCE_LIMITS QoS策略的IDL：
```
struct ResourceLimitsQosPolicy {
  long max_samples;
  long max_instances;
  long max_samples_per_instance;
};
```
成员max_samples表示一个数据写者或数据读者可以管理的所有实例的样本总数。成员max_instances表示数据写者或数据读者可以管理的最大实例数。 成员max_samples_per_instance表示一个数据写者或数据读者可以管理的单个实例的最大样本数。以上成员的默认值都是DDS::LENGTH_UNLIMITED，表示无限制。

该策略应用于数据写者时，写者将把因为传输后压还没有发送给数据读者的样本排队发送；该策略应用于数据读者时，读者将把已接收但还未读取/使用的样本缓存在队列中。

## 7、PARTITION
PARTITION QoS 策略允许在一个域中创建逻辑分区。仅当数据读者和数据写者的分区字符串匹配时，才允许在二者间建立关联关系。该策略主要应用于发布者和订阅者实体，下面是PARTITION QoS策略的IDL：
```
struct PartitionQosPolicy {
  StringSeq name;
};
```
name成员默认值为空，表示实体参与到默认的分区中。分区名可以包含通配符，通配符的规则与POSIX的fnmatch函数（POSIX 1003.2-1992 section B.6）一致。

数据读者和数据写者的关联关系的建立依赖于发布端和订阅端的分区字符串的匹配。如果分区匹配失败，不会触发任何回调或者设置状态值。

该策略的值可以在运行时修改，此修改会引起关联关系的移除或添加。

## 8、DEADLINE
DEADLINE QoS策略允许应用程序在指定的时间内检测数据是否被写入或者读取。该策略主要应用于主题、数据写者、数据读者实体，下面是DEADLINE QoS策略的IDL：
```
struct DeadlineQosPolicy {
  Duration_t period;
};
```
period成员的默认值是无穷大，表示该策略不起作用。如果该策略的值设定为有限值时，数据写者将会监视应用程序的写入行为，当在设定的期限内没有数据写入时，DDS会设置相应的状态条件并触发on_offered_deadline_missed()回调。如果数据读者在设定的期限内没有收到数据时，DDS也会设置相应的状态条件并触发on_offered_deadline_missed()回调。

该策略的兼容性，在数据写者和数据读者建立关联关系的时候就需要考虑。要求：数据读者的period值一定不能小于数据写者的值。

当关联实体被启动之后，该策略的值也是可以修改的。在这种情况下，只有修改后的策略值与关联的实体的策略值一致，才能修改成功。如果该策略用于主题，那么该策略的修改仅仅会影响在改变之后创建的数据读者和数据写者，任何已经创建的读者或者写者，不会受到影响。

## 9、LIFESPAN
LIFESPAN QoS策略允许应用程序指定一个样本什么时候失效。已经失效的样本不会传送给订阅者。该策略主要应用于主题，数据写者实体，下面是LIFESPAN的QoS策略的IDL：
```
struct LifespanQosPolicy {
  Duration_t duration;
}
```
duration成员的默认值是无穷大，表示样本永不失效。OpenDDS1.5支持的LIFESPAN检测是当发布者使用DURABILITY kind时有效。当前的OpenDDS实现并不移除那些已经放入数据读者和数据写者缓存之后失效的样本。

该策略的值可以在运行时修改，修改后的策略只影响之后发布的数据。

## 10、USER_DATA
USER_DATA策略为应用程序提供保存附加信息的方式，该策略主要应用于域参与者、数据读者、数据写者实体，下面是USER_DATA QoS策略的IDL：
```
struct UserDataQosPolicy {
  sequence value;
};
```
Value的默认值为空，表示没有任何附加信息。该字段可以设为任意次序的8-bit，以把信息附加到已经创建的实体中。USER_DATA策略在各自的内建主题数据中都是可以获得的。远端的应用程序通过内建主题获得信息，并根据自己的目的来使用这些信息。例如，应用程序可以使用USER_DATA策略附加安全凭证来认证信息源。

## 11、TOPIC_DATA
TOPIC_DATA策略主要应用于主题，下面是TOPIC_DATA QoS策略的IDL：
```
struct TopicDataQosPolicy {
  sequence value;
};
```
Value的默认值为空，表示没有任何附加信息。该字段可以设为任意次序的8-bit额外信息到主题中。TOPIC_DATA策略对、数据读者，数据写者、主题和内建主题数据有效。远程的应用程序可以通过内建主题获取这些信息，并应用于应用程序自行定义。

## 12、GROUP_DATA
GROUP_DATA策略主要应用于发布者和订阅者实体，下面是GROUP_DATA QoS策略的IDL：
```
struct GroupDataQosPolicy {
  sequence value;
};
```
Value的默认值为空，表示没有任何附加信息。该字段可以设为任意次序的8-bit。GROUP_DATA的值通过内建主题传播。发布端数据写者的内置主题包括GROUP_DATA的值，订阅端则是数据读者包括GROUP_DATA的值。GROUP_DATA策略可以用来实现和在7中描述的PARTITION策略相似的机制。

有关OpenDDS的相关问题欢迎发送邮件至lyingbo@aliyun.com一起讨论
