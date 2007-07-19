#!/bin/bash
# Reconex√o velox/virtua
# necessario colocar no crond
# author: <fams@linuxplace.com.br>
# Version: $Id$
PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

INETIFACE=ppp0
PEER=$(/sbin/route -n|grep $INETIFACE|grep ^0.0.0.0|awk '{print $2}')
OPERADORA=velox
function reconecta(){
	case "$1" in
	"virtua")
		/sbin/shorewall clear
		ifdown $INETIFACE
		sleep 10
		ifup $INETIFACE
		/sbin/shorewall start
	;;
	"velox")
		/sbin/shorewall clear
		poff dsl-provider
		sleep 10
		/sbin/ifconfig eth1 up
		pon dsl-provider
		/sbin/shorewall start
		/etc/init.d/no-ip restart
		/etc/init.d/bind9 restart
	;;
esac
}

if [ -z "$PEER" ];then
	reconecta $OPERADORA
fi
if ( [ "$PEER" = "0.0.0.0" ] && [ "$OPERADORA" = "velox" ] ); then
  PEER=$(/sbin/ip addr list |grep $INETIFACE |grep peer|awk '{print $4}'|cut -d '/' -f 1)
fi
result=$(/bin/ping -w 10 $PEER | grep  "100% packet loss")
if [ ! -z "$result" ];then
	reconecta $OPERADORA
fi
#echo $PEER

