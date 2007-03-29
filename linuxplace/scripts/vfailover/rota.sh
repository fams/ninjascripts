#!/bin/bash

#$Id$

# Comandos
IP="/sbin/ip"

#DEBUG
#echo $0 $1 $2 $3 >> /tmp/debug
#config file
. /etc/vfailover.conf

action=$1

function showdefroute() {
data=`date +%H:%M:%S`
echo $data show >>/tmp/show
  if [ "$($IP route list |grep ^default |grep $PRI_DEV)" ]; then
	echo primary
  elif [ "$($IP route list |grep ^default |grep $SEC_DEV)" ]; then
	echo secondary
  else
  	echo panic
  fi
echo $data show >>/tmp/show
}

function setsecondarydef() {
  $IP route del default 2>/dev/null
  $IP route add default dev $SEC_DEV
  $IP route flush cache
  /usr/bin/killall no-ip 2>/dev/null
  sleep 1
  /usr/bin/no-ip -c /etc/no-ip.conf.velox 2>/dev/null
  showdefroute
}

function setprimarydef() {
  $IP route del default 2>/dev/null
  $IP route add default via $PRI_GW dev $PRI_DEV
  $IP route flush cache
  /usr/bin/killall no-ip >/dev/null
  sleep 1
 /usr/bin/no-ip -c /etc/no-ip.conf.virtua 2>/dev/null
  showdefroute
}


case "$action" in
  show)
    showdefroute
  ;;
  setsecondary)
    setsecondarydef
  ;;
  setprimary)
    setprimarydef
  ;;
  *)
    echo Erro_de_uso
  ;;
esac
echo SAINDO >>/tmp/tulio
