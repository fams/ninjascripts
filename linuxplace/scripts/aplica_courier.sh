#!/bin/bash
LXHOME=/usr/local/linuxplace
#Pega vari�veis
. $LXHOME/config/ldap


#vari�veis auxiliares
#CAMINHOS
STANZAHOME=$LXHOME/stanza
COURIERHOME=$STANZAHOME/courier
ETCCOURIER=/etc/courier

#Arquivos do courier (principalmente authldaprc)
cat $COURIERHOME/authldaprc | sed "s/%SUFFIX%/$SUFFIX/" > $ETCCOURIER/authldaprc
cp -f $COURIERHOME/authdaemonrc $ETCCOURIER/authdaemonrc
cp -f $COURIERHOME/authmodulelist $ETCCOURIER/authmodulelist
