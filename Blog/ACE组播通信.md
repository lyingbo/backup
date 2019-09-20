---
title: ACE组播通信
category: 程序开发
date: 2013-04-14
comments: true
tags:
- ACE
- 组播通信
- ace_sock_dgram_mcast
---

基于ACE的类ACE_SOCK_Dgram_Mcast封装来实现组播发送和接收的简单示例程序

```
// ACE组播类 CMulticast 实现

#include "ace/OS_NS_unistd.h"
#include "ace/INET_Addr.h"
#include "ace/Truncate.h"
#include "ace/Log_Msg.h"
#include "ace/os_include/os_netdb.h"
#include "ace/SOCK_Dgram_Mcast.h"

//  ACE组播 ip
#define DEFAULT_MULTICAST_ADD "239.192.2.3:12345"

//  ACE组播 TTL
#define MAX_MULTICAST_IP_TTL  5

class CMulticast
{

public:

    CMulticast(const char address[]):
     remote_addr_(u_short(0)), multicast_addr_(address)
    {
       //  ACE组播加入组播组
       if (-1 == mcast_dgram_.join(multicast_addr_))
       {
           ACE_ERROR((LM_ERROR, ACE_TEXT("%p\n"), "join()"));
       }

       //  ACE组播 设置 TTL
       if (-1 == mcast_dgram_.set_option(IP_MULTICAST_TTL, MAX_MULTICAST_IP_TTL))
       {
           ACE_ERROR((LM_ERROR, ACE_TEXT("%p\n"), "set_option()"));
       }
    }


private:
    CMulticast(void){};

public:

    ssize_t recv_from_multicast_group(char *buf, size_t n)
    {
       ssize_t ret = mcast_dgram_.recv(buf, n, remote_addr_);

       char hostaddr[MAXHOSTNAME] = {0};
       remote_addr_.addr_to_string(hostaddr, MAXHOSTNAME);
       cout<<"recve from "<<hostaddr<<" data: "<<buf<<endl;

       return ret;
    }

    ssize_t send_to_multicast_group(const char *buf, size_t n)
    {
       ssize_t ret = mcast_dgram_.send(buf, n);

       char hostaddr[MAXHOSTNAME] = {0};
       multicast_addr_.addr_to_string(hostaddr, MAXHOSTNAME);
       cout<<"send to "<<hostaddr<<" data: "<<buf<<endl;

       return ret;
    }

    ~CMulticast(void)
    {
       // ACE组播离开组播组
       if (-1 == mcast_dgram_.leave(multicast_addr_))
       {
           ACE_ERROR((LM_ERROR, ACE_TEXT("%p\n"), "leave()"));
       }
    }

private:
   
    ACE_INET_Addr        multicast_addr_; // 组播组地址
    ACE_INET_Addr        remote_addr_;    // 远端地址
    ACE_SOCK_Dgram_Mcast mcast_dgram_;    //
};


//  ACE组播 发送端调用示例

#include "Multicast.h"

#define data[] = "Hello, world!"

int ACE_TMAIN(int argc, ACE_TCHAR *argv[])
{
    CMulticast mcast(DEFAULT_MULTICAST_ADD);
    while (-1 != mcast.send_to_multicast_group(data, sizeof(data)/sizeof(char)))
    {
       ACE_OS::sleep(2);
    }

    ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("%p\n"), "send()"), 1);
}


//  ACE组播 接收端调用示例

#include "Multicast.h"

int ACE_TMAIN(int argc, ACE_TCHAR *argv[])
{
    CMulticast mcast(DEFAULT_MULTICAST_ADD);
    char buf[256] = {0};
    while (-1 != mcast.recv_from_multicast_group(buf, 255))
    {
       ACE_OS::sleep(2);
    }

    ACE_ERROR_RETURN((LM_ERROR, ACE_TEXT("%p\n"), "recv()"), 1);
}
```

有相关问题欢迎发送邮件至lyingbo@aliyun.com一起讨论
