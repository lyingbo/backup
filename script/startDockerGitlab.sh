#!/bin/bash

# -*- shell -*-
#
# $Id: startDockerGitlab.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

sudo docker run -d \
                --name gitlab \
				--hostname gitlab.lyb.com \
				-p 443:443 -p 80:80 -p 22:22 \
				--restart always \
				-v /home/ostw/gitlab/config:/etc/gitlab \
				-v /home/ostw/gitlab/logs:/var/log/gitlab \
				-v /home/ostw/gitlab/data:/var/opt/gitlab \
				gitlab:10.7.5-ce.0
