#!/bin/bash

#$Id$

# Comandos
IP="/sbin/ip"

#DEBUG
#echo $0 $1 $2 $3 >> /tmp/debug

# Variaveis
VELOXIF="ppp0"
EMBRAIF="eth1"
EMBRAGW="200.251.121.1"

action=$1

function showdefroute() {
  if [ "$($IP route list |grep ^default |grep $EMBRAIF)" ]; then
	echo dedicado
  elif [ "$($IP route list |grep ^default |grep $VELOXIF)" ]; then
	echo velox
  else
  	echo panic
  fi
}

function setveloxdef() {
  $IP route del default 2>/dev/null
  $IP route add default dev $VELOXIF
  $IP route flush cache
  showdefroute
}

function setembradef() {
  $IP route del default 2>/dev/null
  $IP route add default via $EMBRAGW dev $EMBRAIF
  $IP route flush cache
  showdefroute
}


case "$action" in
  show)
    showdefroute
  ;;
  setvelox)
    setveloxdef
  ;;
  setembratel)
    setembradef
  ;;
  setdedicado)
    setembradef
  ;;
  *)
    echo Erro_de_uso
  ;;
esac
