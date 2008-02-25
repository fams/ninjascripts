#!/bin/bash

#$Id: rota.sh,v 1.3 2007/03/29 01:36:53 fams Exp $

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
	if [ "$($IP rule list |grep ^1:)" ] ;then
		echo both
	else
		echo primary
	fi
  elif [ "$($IP route list |grep ^default |grep $SEC_DEV)" ]; then
	echo secondary
  else
  	echo panic
  fi
echo $data show >>/tmp/show
}

function setsecondarydef() {
$IP route del default 2>/dev/null
$IP rule del pref 1
$IP route add default dev $SEC_DEV
$IP route flush cache

showdefroute
		 
}

function setprimarydef() {
$IP route del default 2>/dev/null
$IP rule del pref 1
$IP route add default via $PRI_GW dev $PRI_DEV
showdefroute
}

function setbothdef(){
$IP route del default 2>/dev/null
$IP rule del pref 1

#$IP route add default via $PRI_GW dev $PRI_DEV table $PRI_TABLE
$IP rule  add pref 001 fwmark 1 table $SEC_TABLE #Rota para os servicos especificados
$IP route add default via $PRI_GW dev $PRI_DEV

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
  
  setboth)
    setbothdef
  ;;
  *)
  
    echo Erro_de_uso
  ;;
esac
echo SAINDO >>/tmp/teste
