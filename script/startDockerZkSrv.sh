#!/bin/bash

# -*- shell -*-
#
# $Id: startDockerZkSrv.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

sudo docker run --name zookeeperS --restart always -d zookeeper
