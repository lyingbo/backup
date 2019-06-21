#!/bin/bash

# -*- shell -*-
#
# $Id: startDockerZkCli.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

sudo docker run -it --rm --link zookeeperS:zookeeper zookeeper zkCli.sh -server zookeeper
