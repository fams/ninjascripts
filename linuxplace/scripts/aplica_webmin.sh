#!/bin/sh
LXHOME=/usr/local/linuxplace
#Pega variáveis
. $LXHOME/config/ldap
. $LXHOME/config/lxn
. $LXHOME/config/webmin

#variáveis auxiliares
#CAMINHOS
STANZAHOME=$LXHOME/stanza
WEBMINHOME=$STANZAHOME/webmin
ETCWEBMIN=/etc/webmin

####Miniserv config
FQDN=$(hostname -f)
MYNETWORKA=$(echo $MYNETWORK|cut -f1 -d/)
MYNETWORKM=$(ipcalc -n  $MYNETWORK|grep Netmask:|awk '{print $2}')
sed -e "s/%FQDN%/$FQDN/;s/%LOCALNET%/$MYNETWORKA\/$MYNETWORKM/" $WEBMINHOME/miniserv.conf >$ETCWEBMIN/miniserv.conf

#####IDXLDAPACCOUNTS
mkdir -p $ETCWEBMIN/idxldapaccounts
sed -e "s/%SUFFIX%/$SUFFIX/;s/%LDAPPROXYPASS%/linuxplace/" $WEBMINHOME/idxldapaccounts/config >$ETCWEBMIN/idxldapaccounts/config

###Usuario de gereciamento
adduser --disabled-password --gecos "Usuario webmin" admproxy
passwd -u admproxy
echo admproxy:$WEBMINPW |/usr/sbin/chpasswd

grep -v admproxy $ETCWEBMIN/miniserv.users >$ETCWEBMIN/miniserv.users.$$
echo -e "admproxy:0:0::\n" >>$ETCWEBMIN/miniserv.users.$$
mv $ETCWEBMIN/miniserv.users $ETCWEBMIN/miniserv.users.old
mv $ETCWEBMIN/miniserv.users.$$ $ETCWEBMIN/miniserv.users

grep -v admproxy $ETCWEBMIN/webmin.acl >$ETCWEBMIN/webmin.acl.$$
echo "admproxy: sysstats squid idxldapaccounts postfix" >>$ETCWEBMIN/webmin.acl.$$
mv $ETCWEBMIN/webmin.acl $ETCWEBMIN/webmin.acl.old
mv $ETCWEBMIN/webmin.acl.$$ $ETCWEBMIN/webmin.acl
#acl do admproxy
cp -f $WEBMINHOME/squid/admproxy.acl $ETCWEBMIN/squid/
cp -f $WEBMINHOME/sysstats/config $ETCWEBMIN/sysstats/
