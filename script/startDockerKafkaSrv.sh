#!/bin/bash

# -*- shell -*-
#
# $Id: kafkaSrv.sh  2019-08-08 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-08-08 18:45:46
#    Description :

sudo docker run -d --name kafka --restart always -p 9092:9092 \
    --link zookeeper \
    -e KAFKA_BROKER_ID=0 \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_HOST_NAME=127.0.0.1 \
    -e KAFKA_ADVERTISED_PORT=9092 \
    kafka

