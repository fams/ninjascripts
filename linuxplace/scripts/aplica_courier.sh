#!/bin/bash
LXHOME=/usr/local/linuxplace
#Pega variáveis
. $LXHOME/config/ldap


#variáveis auxiliares
#CAMINHOS
STANZAHOME=$LXHOME/stanza
COURIERHOME=$STANZAHOME/courier
ETCCOURIER=/etc/courier
ETCMAILDROP=/etc/maildrop

#Arquivos do courier (principalmente authldaprc)
cat $COURIERHOME/authldaprc | sed "s/%SUFFIX%/$SUFFIX/" > $ETCCOURIER/authldaprc
cat $COURIERHOME/maildropldap.config | sed "s/%SUFFIX%/$SUFFIX/" > $ETCMAILDROP/maildropldap.config
cp -f $COURIERHOME/authdaemonrc $ETCCOURIER/authdaemonrc
cp -f $COURIERHOME/authmodulelist $ETCCOURIER/authmodulelist
