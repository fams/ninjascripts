#!/bin/sh
################################################################################
#Config SQUID
################################################################################
LXHOME=/usr/local/linuxplace
#Pega variáveis
. $LXHOME/config/ldap
. $LXHOME/config/lxn
. $LXHOME/config/squid

#variáveis auxiliares
#CAMINHOS
STANZAHOME=$LXHOME/stanza
WEBMINHOME=$STANZAHOME/webmin
ETCSQUID=/etc/squid
LOCALNET=$(echo $LOCALNET|sed -e 's/\//\\\//')

cat $STANZAHOME/squid/squid.conf|sed -e "
s/%LOCALNET%/$LOCALNET/g
s/%REALM%/$REALM/g
s/%LISTEN%/$LISTEN/g
s/%SUFFIX%/$SUFFIX/g
">/etc/squid/squid.conf
mkdir -p /etc/squid/acl 2>/dev/null
test -f /etc/squid/acl/url_rest.acl || echo -e "-i\nmp3"> /etc/squid/acl/url_rest.acl
test -f /etc/squid/acl/destino_priv.acl || echo "unimedmg.com.br"> /etc/squid/acl/destino_priv.acl
test -f /etc/squid/acl/destino_noauth.acl || echo -e"obsupgdp.caixa.gov.br\nwindowsupdate.microsoft.com\nliveupdate.symantec.com\nsymantecliveupdate.com"> /etc/squid/acl/destino_noauth.acl
test -f /etc/squid/acl/destino_rest.acl || echo "consumptionjunction.com" > /etc/squid/acl/destino_rest.acl
test -f /etc/squid/acl/usuarios_priv.acl || echo "none" > /etc/squid/acl/usuarios_priv.acl
test -f /etc/squid/acl/usuarios_rest.acl || echo "none" > /etc/squid/acl/usuarios_rest.acl
################################################################################
