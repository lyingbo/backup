#!/bin/bash

# -*- shell -*-
#
# $Id: startDockerHdfsDN.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

sudo docker run -d --rm \
                --name datanode1 \
				--hostname datanode1 \
				--network  hadoopnet \
				--ip 172.18.0.13 \
				-v $PWD/data:/opt/tmp \
				-v $PWD/hadoop:/opt/hadoop-2.6.5/etc/hadoop \
				wsn/ubuntu_ssh_java_hadoop
				
sudo docker run -d --rm \
                --name datanode2 \
				--hostname datanode2 \
				--network  hadoopnet \
				--ip 172.18.0.14 \
				-v $PWD/data:/opt/tmp \
				-v $PWD/hadoop:/opt/hadoop-2.6.5/etc/hadoop \
				wsn/ubuntu_ssh_java_hadoop 
