#!/bin/bash

# -*- shell -*-
#
# $Id: addDockerAccess.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

sudo groupadd docker;
sudo gpasswd -a ${USER} docker;
sudo systemctl restart docker;
