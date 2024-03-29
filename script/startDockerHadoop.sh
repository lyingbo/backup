#!/bin/bash

# -*- shell -*-
#
# $Id: startDockerHadoop.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

# create docker network hadoop
#docker network create --driver=bridge hadoop

# the default node number is 4
N=${1:-3}

# start hadoop master container
docker rm -f hadoop-master > /dev/null
echo "start hadoop-master container..."
docker run -itd \
           --net=hadoop \
           -p 9870:9870 \
           -p 8088:8088 \
           -v /mnt/hgfs/vmShare:/home/vmShare \
           --name hadoop-master \
           --hostname hadoop-master \
           hadoop:1.0 /usr/sbin/sshd -D > /dev/null

# start hadoop slave container
i=1
while [ $i -lt $N ]
do
    docker rm -f hadoop-slave$i > /dev/null
    echo "start hadoop-slave$i container..."
    docker run -itd \
               --net=hadoop \
               -v /mnt/hgfs/vmShare:/home/vmShare \
               --name hadoop-slave$i \
               --hostname hadoop-slave$i \
               hadoop:1.0 /usr/sbin/sshd -D > /dev/null
    i=$(( $i + 1 ))
done 

# get into hadoop master container
docker exec -it hadoop-master bash


