#!/bin/bash

# -*- shell -*-
#
# $Id: startDockerRedis.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

sudo docker run -d \
                --name redis \
				--hostname redis.lyb.com \
				-p 6379:6379 \
				--restart always \
				-v /home/ostw/redis/config/redis.conf:/usr/local/etc/redis/redis.conf \
				-v /home/ostw/redis/data:/data \
				redis redis-server --appendonly yes 
