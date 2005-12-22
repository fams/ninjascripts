#!/bin/bash
#pega variáveis
LXBASE=/usr/local/linuxplace
. $LXBASE/config/lxn
. $LXBASE/config/ldap
. $LXBASE/config/horde

#Variáveis auxiliares
#CAMINHOS
STANZABASE=$LXBASE/stanza
HORDEBASE=$STANZABASE/horde/horde3
TURBABASE=$STANZABASE/horde/turba2
IMPBASE=$STANZABASE/horde/imp4
APACHEBASE=$STANZABASE/horde/apache2
ETCHORDE=/etc/horde/horde3
ETCTURBA=/etc/horde/turba2
ETCIMP=/etc/horde/imp4
ETCAPACHE=/etc/apache2

#configs horde3
cat $HORDEBASE/conf.php |sed "s/%SUFFIX%/$SUFFIX/;s/%ADMIN%/$ADMIN/;s/%MAILDOMAIN%/$MAILDOMAIN/" > $ETCHORDE/conf.php
cat $HORDEBASE/hooks.php |sed "s/%SUFFIX%/$SUFFIX/" > $ETCHORDE/hooks.php
cp -f $HORDEBASE/prefs.php $ETCHORDE/prefs.php
cp -f $HORDEBASE/nls.php $ETCHORDE/nls.php

#configs turba2
cat $TURBABASE/sources.php |sed "s/%EMPRESA%/$EMPRESA/;s/%SUFFIX%/$SUFFIX/;s/%LDAPPROXYPASS%/$LDAPPROXYPASS/;s/%ADMIN%/$ADMIN/" > $ETCTURBA/sources.php
cp -f $TURBABASE/conf.php $ETCTURBA/conf.php

#configs imp4
cat $IMPBASE/servers.php |sed "s/%MAILDOMAIN%/$MAILDOMAIN/" > $ETCIMP/servers.php
cp -f $IMPBASE/conf.php $ETCIMP/conf.php

#virtual servers (int/ext) para o apache
#interno
cat $APACHEBASE/virtualdomain.stanza |sed "s/%ADMIN%/$ADMIN/;s/%VIRTUALDOMAIN%/$INTERNALDOMAIN/" > $ETCAPACHE/sites-available/webmail-int
ln -s $ETCAPACHE/sites-available/webmail-int $ETCAPACHE/sites-enabled

#externo
cat $APACHEBASE/virtualdomain.stanza |sed "s/%ADMIN%/$ADMIN/;s/%VIRTUALDOMAIN%/$MAILDOMAIN/" > $ETCAPACHE/sites-available/webmail
ln -s $ETCAPACHE/sites-available/webmail $ETCAPACHE/sites-enabled
