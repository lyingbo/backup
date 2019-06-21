#!/bin/bash

# -*- shell -*-
#
# $Id: registService.sh  2019-06-18 18:45:46 $
#************************************************************************
#    Author      : NoName <lyingbo@aliyun.com>
#    Date        : 2019-06-18 18:45:46
#    Description :
#************************************************************************

scpt=$(readlink -f $0)
workDir=$(dirname $scpt)
program=SmartlabServer
#program=SmartNodeDemon

start() {
    userName="ostw"
    sudo -su $userName export SMARTLABSDK=/workSpace/product/smartlab/RuntimeSdk
    sudo -su $userName export NDDSHOME=/home/ostw/rti_connext_dds-5.3.1
    sudo -su $userName export QTDIR=/home/ostw/Qt5.5.1/5.5/gcc_64
    sudo -su $userName export LD_LIBRARY_PATH=$QTDIR/lib:$NDDSHOME/lib/x64Linux3gcc5.4.0:$SMARTLABSDK/lib
    sudo -su $userName export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$QTDIR/bin:$NDDSHOME/bin

    sudo -su $userName $workDir/$program &
}

stop() {
    killall $program
}

help() {
    echo -e "Usage: $0 {start|stop|restart|install|remove}"
}

install() {
    sudo ln -s $workDir/registService.sh /etc/init.d/smartlab
    sudo update-rc.d smartlab defaults
}

remove() {
    sudo update-rc.d -f smartlab remove
    sudo rm /etc/init.d/smartlab
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
    install)
        install
        ;;
    remove)
        remove
        ;;
    *)
        help
        ;;
esac
