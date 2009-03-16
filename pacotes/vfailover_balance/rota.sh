#!/bin/bash

#$Id: rota.sh,v 1.3 2007/03/29 01:36:53 fams Exp $

# Comandos
IP="/sbin/ip"

#DEBUG
#echo $0 $1 $2 $3 >> /tmp/debug
#config file

. /usr/lib/cfgparser.sh



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
$IP rule del pref 1 >/dev/null 2>&1
$IP route add default via $SEC_GW dev $SEC_DEV
$IP route flush cache

showdefroute
		 
}

function setprimarydef() {
$IP route del default 2>/dev/null
$IP rule del pref 1 >/dev/null 2>&1
$IP route add default via $PRI_GW dev $PRI_DEV
showdefroute
}

function setbothdef(){
$IP route del default 2>/dev/null
$IP rule del pref 1 2>/dev/null

#$IP route add default via $PRI_GW dev $PRI_DEV table $PRI_TABLE
$IP rule  add pref 001 fwmark 1 table $SEC_TABLE #Rota para os servicos especificados
$IP route add default via $PRI_GW dev $PRI_DEV
showdefroute
}

##########################  INICIO #########################
init=/etc/vfailover.ini

#while getopts c: o
#do
#    case $o in
#    c)  init="$OPTARG";;
#    [?])    print >&2 "Uso: $0 [-c inifile] file ..."
#        exit 1;;
#    esac
#done
#shift $OPTIND-1

#
# Processa INI
#

cfg.parser $init
cfg.section.tables
cfg.section.rota
#Sobrescreve os parametros do ini com os valores recebidos via dhcp se houver
if [ -f /var/run/vfailover/pri.state ];then
    . /var/run/vfailover/pri.state
fi
if [ -f /var/run/vfailover/sec.state ];then
    . /var/run/vfailover/sec.state
fi
    

		    
action=$1

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
