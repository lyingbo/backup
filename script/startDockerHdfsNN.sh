#!/bin/bash

# -*- shell -*-
#
# $Id: startDockerHdfsNN.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

sudo docker run -itd --rm \
                --name namenode \
				--hostname namenode \
				--network  hadoopnet 
				--ip 172.18.0.11 \
				-v $PWD/data:/opt/tmp \
				-v $PWD/hadoop:/opt/hadoop-2.6.5/etc/hadoop \
				-v $PWD/run.sh:/opt/run.sh \
				wsn/ubuntu_ssh_java_hadoop /opt/run.sh
