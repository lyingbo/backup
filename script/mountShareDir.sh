#!/bin/bash

# -*- shell -*-
#
# $Id: mountShareDir.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

#sudo vmhgfs-fuse -e
#sudo vmhgfs-fuse -o subtype=vmhfs-fuse,allow_other /mnt/hgfs/

sudo mount -t vboxsf vmShare /mnt/hgfs/vmShare/

