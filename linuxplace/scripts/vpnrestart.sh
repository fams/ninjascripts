#!/bin/sh
conf=loja49

openvpn=/etc/init.d/openvpn
remoteip=$(cat /etc/openvpn/$conf.conf|grep "^[^#;]\?[ \t]*ifconfig"|awk '{print $3}')
ping -c 2 -w 2 $remoteip|grep 100% 
ret=$?
if [ $ret -ne 1 ]; then
	$openvpn restart $conf
fi
