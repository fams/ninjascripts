#!/bin/sh
# Aplica.sh
# Script para aplicar configuracoes do gedai
# Copyright 2004 by Fernando Augusto Medeiros Silva <fams at linuxplace dot com dot br>
# Licensed under the GPL, version 2 or higher.
#
. /etc/gedai/config
. /usr/share/gconfig/funcs.sh
root=/usr/share/gconfig/root
SUFFIX="dc=$HOSTGEDAI,dc="`hostname -d|sed 's/\./,dc=/g'`
>$root/etc/servicerules
randompass(){
dd if=/dev/urandom  count=100 2>/dev/null|md5sum
}
setservice(){
	update-rc.d -f  $1 remove >/dev/null 2>&1 
	case $1 in
	bind9)
		update-rc.d bind9 $2 19 2 .
	;;
	dnsmasq)
		update-rc.d dnsmasq $2 15 2 .
	;;
	slapd)
		update-rc.d slapd $2 19 2 .
	;;
	postfix)
		update-rc.d postfix $2 19 2 .
		update-rc.d saslauthd $2 19 2 .
	;;
	squid)
		update-rc.d squid $2 30 2 .
	;;
	p3scan)
		update-rc.d p3scan $2 30 2 .
		update-rc.d spamassassin $2 29 2 .
	;;
	dhcpd)
		update-rc.d dhcpd $2 20 2 .
	;;
	ssh)
		update-rc.d ssh $2 20 2 .
	;;
	nscd)
		update-rc.d nscd $2 20 2 .
	;;
	shorewall)
		update-rc.d shorewall $2 20 2 .
	;;
	amavis)
		update-rc.d amavis $2 20 2 .
	;;
	webmin)
		update-rc.d webmin $2 30 2 .
	;;
	clamav-daemon)
		update-rc.d clamav-daemon $2 20 2 .
	;;
	clamav-freshclam)
		update-rc.d clamav-freshclam $2 20 2 .
	;;
	snort)
		update-rc.d snort $2 40 2 .
	;;
	nagios-nrpe-server)
		update-rc.d nagios-nrpe-server $2 20 2 .
	;;
	

esac
	
}

################################################################################
#Config Webmin
################################################################################

configwebmin(){
	local FQDN=`hostname -f`
	SRINT=`echo $RINT|cut -f1 -d/`
	RMASK=`ipcalc -n  $RINT|grep Netmask:|awk '{print $2}'`
	sed -e "s/%FQDN%/$FQDN/;s/%LOCALNET%/$SRINT\/$RMASK/" $root/etc/webmin/miniserv.conf >/etc/webmin/miniserv.conf
	#webmin squid
	adduser --disabled-password --gecos "Usuario webmin" admproxy
	passwd -u admproxy
	/usr/share/gconfig/autopasswd admproxy $WEBMINPW
	echo -e "root:x:0::\nadmproxy:x:0::" >/etc/webmin/miniserv.users
	cp -f $root/etc/webmin/squid/admproxy.acl /etc/webmin/squid/
	cp -f $root/etc/webmin/webmin.acl /etc/webmin/
	cp -f $root/etc/webmin/sysstats/config /etc/webmin/sysstats/
	echo "admproxy: sysstats squid idxldapaccounts" >>/etc/webmin/webmin.acl

	setservice webmin start
	invoke-rc.d webmin restart
}
################################################################################

################################################################################
#Config DNS
################################################################################

configdns(){
#salvando arquivos atuais
	if [ ! -z "$FORWARD" ];then
	FORWARD="forwarders {$FORWARD ;} ;"
	fi
#configurando named.conf
#RINT sem a rede
SRINT=`echo $RINT|cut -f1 -d/`
RRINT=`echo $RINT|awk -F. '{print $3 "." $2 "." $1}'`
cat $root/etc/bind/named.conf |sed -e "
s/%DOMINT%/$DOMINT/g
s/%RINT%/$SRINT/g
s/%FORWARD%/$FORWARD/g
s/%RRINT%/$RRINT/g
" > /var/lib/named/etc/bind/named.conf
rm -f /etc/bind/named.conf
ln -s /var/lib/named/etc/bind/named.conf /etc/bind
#configurando zonas
#Master
export SERIAL=`date +'%Y%m%d'`1
cat $root/var/lib/named/db/master/%DOMINT%.hosts|sed -e "
s/%DOMINT%/$DOMINT/g
s/%IPINT%/$IPINT/g
s/%HOSTGEDAI%/$HOSTGEDAI/g
s/%SERIAL%/$SERIAL/g
" >/var/lib/named/db/master/$DOMINT.hosts
#Reverso
RIP_ROUTER=`echo $IP_ROUTER|awk -F. '{print $4 "." $3 "." $2 "." $1}'`
cat $root/var/lib/named/db/master/%RINT%.rev|sed -e "
s/%DOMINT%/$DOMINT/g
s/%IPINT%/$IPINT/g
s/%HOSTGEDAI%/$HOSTGEDAI/g
s/%SERIAL%/$SERIAL/g
s/%RRINT%/$RRINT/g
s/%RIP_ROUTER%/$RIP_ROUTER/g
" >/var/lib/named/db/master/`echo $SRINT|awk -F. '{print $1 "." $2 "." $3}'`.rev
#Reverso
#necessario para pid file???
if [ ! -d /var/lib/named/var/run ] ; then
	mkdir -p /var/lib/named/var/run
fi
chown -R bind.bind /var/lib/named/var
cp -f $root/etc/default/bind9 /etc/default/
#criar diretorios no chroot
if [ ! -d /var/lib/named/dev ] ; then
  mkdir -p /var/lib/named/dev
fi
#criar devices no chroot
mknod /var/lib/named/dev/null c 1 3
mknod /var/lib/named/dev/random c 1 8
#gera rndc.key
rndc-confgen -a -c /var/lib/named/etc/bind/rndc.key
chmod 644 /var/lib/named/etc/bind/rndc.key
#acerta arquivos de configuracao
rm -rf /etc/bind/*
cd /etc/bind
for i in /var/lib/named/etc/bind/* ; do ln -s $i . ; done
cd -
}
################################################################################

################################################################################
#CONFIG DHCP
################################################################################

configdhcp(){
#Gerando variaveis
#rede interna sem a mascara
SRINT=`echo $RINT|cut -f1 -d/`
#Mascara da rede interna
RMASK=`ipcalc -n  $RINT|grep Netmask:|awk '{print $2}'`
#Broadcast rede interna
RBCAST=`ipcalc -n  $RINT|grep Broadcast:|awk '{print $2}'`
cat $root/etc/dhcpd.conf|sed -e "
s/%RINT%/$SRINT/g
s/%IPINT%/$IPINT/g
s/%RMASK%/$RMASK/g
s/%DHCP_IP_INICIAL%/$DHCP_IP_INICIAL/g
s/%DHCP_IP_FINAL%/$DHCP_IP_FINAL/g
s/%DOMINT%/$DOMINT/g
s/%DNS_INTERNO%/$DNS_INTERNO/g
s/%RBCAST%/$RBCAST/g
">/etc/dhcpd.conf
cp -f $root/etc/default/dhcp /etc/default/
}
################################################################################


################################################################################
#Config SQUID
################################################################################

configsquid(){
SRINT=`echo $RINT|cut -f1 -d/`
RMASK=`ipcalc -n  $RINT|grep Netmask:|awk '{print $2}'`
cat $root/etc/squid/squid.conf|sed -e "
s/%RINT%/$SRINT/g
s/%RMASK%/$RMASK/g
s/%SUFFIX%/$SUFFIX/g
s/%DOMINT%/$DOMINT/g
">/etc/squid/squid.conf
mkdir -p /etc/squid/acl 2>/dev/null
test -f /etc/squid/acl/url_rest.acl || echo -e "-i\nmp3"> /etc/squid/acl/url_rest.acl
test -f /etc/squid/acl/destino_priv.acl || echo "unimedmg.com.br"> /etc/squid/acl/destino_priv.acl
test -f /etc/squid/acl/destino_noauth.acl || echo -e"obsupgdp.caixa.gov.br\nwindowsupdate.microsoft.com\nliveupdate.symantec.com\nsymantecliveupdate.com"> /etc/squid/acl/destino_noauth.acl
test -f /etc/squid/acl/destino_rest.acl || echo "consumptionjunction.com" > /etc/squid/acl/destino_rest.acl
test -f /etc/squid/acl/usuarios_priv.acl || echo "none" > /etc/squid/acl/usuarios_priv.acl
test -f /etc/squid/acl/usuarios_rest.acl || echo "none" > /etc/squid/acl/usuarios_rest.acl
}
################################################################################

################################################################################
#Config Postfix
################################################################################

configpostfix(){
	if [ "$POSTFIX" = "NAO" ]; then
		return 0;
	fi
	if  checkip $RELAY_HOST ; then
		SEDSCR="s/%RELAYHOST%/relayhost=[$RELAY_HOST]/;"
	else 
		SEDSCR="s/%RELAYHOST%/relayhost=$RELAY_HOST/;"
	fi
	
	if [ "$SMTP_USER" != "" ]; then
	SEDSCR="$SEDSCR s/%SA%//;"
	SEDSCR="$SEDSCR s/%SA_LOGIN%/smtp_ssl_auth_password_maps=static:$SMTP_USER:$SMTP_PASS/;"
	else
	SEDSCR="$SEDSCR s/%SA_LOGIN%//;"
	SEDSCR="$SEDSCR s/%SA%/#/;"
	fi
	SEDSCR="$SEDSCR s/%HOSTGEDAI%/$HOSTGEDAI/;"
	SEDSCR="$SEDSCR s/%DOMINT%/$DOMINT/;"
	cat $root/etc/postfix/main.cf|sed -e "$SEDSCR" >/etc/postfix/main.cf
	cp -f $root/etc/postfix/master.cf /etc/postfix/master.cf
	#aliases
	pushd /etc
	newaliases
	popd
	#############Configurando o sasl
	cat $root/etc/saslauthd.conf |sed -e "s/%SUFFIX%/$SUFFIX/">/etc/saslauthd.conf
	cp -f $root/etc/default/saslauthd /etc/default/
	#config do postfix para sasl
	cp -f $root/etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/
		setservice saslauthd start
	
	################Configs do amavisd-new
	cat $root/etc/amavisd.conf |sed -e" s/%DOMINT%/$DOMINT/g " > /etc/amavis/amavisd.conf
	chown -R amavis.amavis /var/lib/clamav
	chown -R amavis.adm /var/log/clamav
	chown -R amavis.amavis /var/run/clamav
	cp -f $root/etc/logrotate.d /etc/logrotate.d
	cp -f $root/etc/clamav/* /etc/clamav
	cat <<eof >>$root/etc/servicerules
##### Gateway de Correio Gedai #################################################
ACCEPT	rloc	$FW	tcp	25	-
#------------------------------------------------------------------------------#
eof
}
################################################################################

################################################################################
#Config pop3proxy
################################################################################
configp3scan(){
   chown amavis /var/spool/p3scan -R
   cp -f $root/etc/p3scan/p3scan.conf /etc/p3scan
   cp -f $root/etc/default/spamassassin /etc/default
   cat <<eof >>$root/etc/servicerules
##### POP3 Scan ###############################################################
REDIRECT	rloc	8110	tcp	110	-
#------------------------------------------------------------------------------#
eof
}
################################################################################
#Config LDAP
################################################################################

configldap(){
#limpando a base
adduser --disabled-password --gecos "Usuario LDAP" ldap
cp -f $root/etc/default/slapd /etc/default/slapd

/etc/init.d/slapd stop
killall slapd
rm -Rf /var/lib/ldap/*
#configuracao
LROOTPW=`slappasswd -h{MD5} -s $ROOTPW|sed -e 's/\//\\\\\//'`

cat $root/etc/ldap/slapd.conf|sed -e "
s/%SUFFIX%/$SUFFIX/
s/%ROOTPW%/$LROOTPW/
">/etc/ldap/slapd.conf
cat $root/etc/ldap/slapd.access.conf|sed -e "
s/%SUFFIX%/$SUFFIX/
">/etc/ldap/slapd.access.conf
#copiando schemas 
cp $root/etc/ldap/schema/* /etc/ldap/schema
#Criando base
chmod 644 /etc/ldap/slapd.conf
chown -R ldap.ldap /var/lib/ldap
chown -R ldap.ldap /var/run/slapd
/etc/init.d/slapd start
ret=$?
sleep 1
if [ $ret -eq 0 ]; then
	TMPLDIF=`mktemp /tmp/linit.XXXXXX`
	PROXYPW=`randompass|awk '{print $1}'`
	LPROXYPW=`slappasswd -h{MD5} -s $PROXYPW|sed -e 's/\//\\\\\//'`
	cat $root/etc/ldap/init.ldif|sed -e "
s/%BASEDC%/$HOSTGEDAI/
s/%SUFFIX%/$SUFFIX/
s/%ROOTPW%/$LROOTPW/
s/%PROXYPW%/$LPROXYPW/
">$TMPLDIF
	/usr/bin/ldapadd -D"cn=Manager,$SUFFIX" -x -w$ROOTPW -f $TMPLDIF
	echo $PROXYPW>/etc/ldap.secret
	rm -f $TMPLDIF
#config do modulo idxldapaccount do webmin
	cat $root/etc/webmin/idxldapaccounts/config |sed -e "
	s/%SUFFIX%/$SUFFIX/
	s/%ROOTPW%/$ROOTPW/
">/etc/webmin/idxldapaccounts/config
	mkdir -p /home/remote
	rm -f /etc/nsswitch.conf
	cp -f $root/etc/nsswitch.conf /etc/nsswitch.conf
#config libnss-ldap
	rm -f /etc/libnss-ldap.conf
	cat $root/etc/libnss-ldap.conf | sed -e " 
	s/%SUFFIX%/$SUFFIX/" > /etc/libnss-ldap.conf
fi
}

################################################################################

################################################################################
#Config Nagios Remote Plugin Executor (NRPE)
################################################################################
confignrpe(){
	cat $root/etc/nagios/nrpe_local.cfg | sed -e "
	s/%SUFFIX%/$SUFFIX/" > /etc/nagios/nrpe_local.cfg
	cat $root/etc/nagios/nrpe.cfg | sed -e " 
	s/%IP_ROUTER%/$IP_ROUTER/" > /etc/nagios/nrpe.cfg
}
################################################################################

#Estes serviços estarao sempre ativos
setservice ssh start
invoke-rc.d ssh start
setservice nscd start
invoke-rc.d nscd start
case $DNS in
	SIM)
		configdns
		setservice bind9 start
		invoke-rc.d bind9 start
		setservice dnsmasq stop
		invoke-rc.d dnsmasq stop
	;;
	NAO)
		setservice bind9 stop
		invoke-rc.d bind9 stop
		setservice dnsmasq stop
		invoke-rc.d dnsmasq stop
	;;
	MASQ)
		setservice bind9 stop
		invoke-rc.d bind9 stop
		setservice dnsmasq start
		invoke-rc.d dnsmasq start
	;;
esac
if [ "$POSTFIX" = "SIM" -o "$CACHE" = "SIM" ]; then
	configldap
	setservice slapd start
else
	setservice slapd stop
fi

case $POSTFIX in
	SIM)
		configpostfix
		setservice  postfix start
		setservice  amavis start
		setservice  clamav-daemon start
		setservice  clamav-freshclam start
		invoke-rc.d postfix start
		invoke-rc.d amavis start
		invoke-rc.d clamav-daemon stop
		killall clamd
		invoke-rc.d clamav-daemon start
		invoke-rc.d clamav-freshclam start
	;;
	NAO)
		setservice  postfix stop
	;;
esac
case $POP3PROXY in
	SIM)
		configp3scan
		setservice p3scan start
		invoke-rc.d p3scan start
		setservice spamassassin start
		invoke-rc.d spamassassin start
	;;
	NAO)
		setservice  p3scan stop
		setservice  spamassassin stop
	;;
esac
case $CACHE in
	SIM)
		configsquid
		setservice  squid start
		invoke-rc.d squid start
	;;
	NAO)
		setservice  squid stop
	;;
esac
case $DHCP in
	SIM)
		configdhcp
		setservice  dhcp start
		invoke-rc.d dhcp start
	;;
	NAO)
		setservice  dhcp stop
	;;
esac
####Shorewall
(cd /etc/shorewall;tar -xvzf $root/etc/swrules.tar.gz >/dev/null)
cp -f /usr/share/gconfig/root/etc/default/shorewall /etc/default/shorewall
cat $root/etc/servicerules >>/etc/shorewall/rules
echo "#LAST LINE -- ADD YOUR ENTRIES BEFORE THIS ONE -- DO NOT REMOVE" >>/etc/shorewall/rules
setservice shorewall start
invoke-rc.d shorewall start

##########SSHD
#cria o usuario suporte. LEMBRAR DE COLOCAR O CODIGO PARA COPIAR A CHAVE DELE
#o usuario suporte nao pode logar localmente
groupadd -g 113 wheel
adduser --disabled-password --gecos "Usuario Suporte Gedai" --ingroup wheel suporte
usermod suporte -G wheel
mkdir /home/suporte/.ssh
cat >>/home/suporte/.ssh/authorized_keys2 <<eof
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAtXaYOuQw61li41mIH/ZoC552zFAAvjb7+g2MJ6Rc+hrR2CdUTq3dsW4Viwt0vbcQQ/lsoOJ4AO1kNZj2d5Td3aUwiYI9OL2VAMDtfx+2UQhmur4XC00IU+7Ro+JLOkXzIQJy+dh9NOfPE73DY+YV9o/Z2FDsU7KDEc8RCCHafuc= Gedai suporte
eof
chown suporte.users /home/suporte/.ssh/authorized_keys2

mkdir /root/.ssh
cat >/root/.ssh/authorized_keys2 <<eof
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAymXb/x2RPe85Pnude9HTQtuLupV1kVFLLVBeDUhVdN4pKNEi/BMR2JGcM8AgHps+RAebMFtW6m8rM0gH4M+MZtp7JdcDWaXN+n3n08+T9mPY7PS2if5Gou5s6hqFpUhVqVhcIjbAS/C46Y0MfkT5W9NEfCHg3O0AVGXNQ97fOe0= Gedai root
eof

#Cria a chave ssh do host.
#Isto é necessario porque o gedai é clonado.
rm -rf /etc/ssh/ssh_host*_key
ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -t dsa -N "" -f /etc/ssh/ssh_host_dsa_key

#Acertos para o apt funcionar sob ssh
cp -f $root/etc/apt/sources.list /etc/apt/sources.list
for i in config repositorio.pub id_rsa.repositorio 
do 
	cp -f $root/etc/ssh/$i /root/.ssh/$i 
done
#necessario, senao o sshd torna a chave invalida
chmod 600 /root/.ssh/id_rsa.repositorio

#para o sshd nao permitir root login
cp -f $root/etc/ssh/sshd_config /etc/ssh/sshd_config

#apenas os usuarios do grupo wheel podem usar o su
cp -f $root/etc/pam.d/su /etc/pam.d/su

#INCLUIR AQUI O CODIGO PARA ASSINAR E ENVIAR A SENHA VIA E_MAIL.

#######Nagios (NRPE) ########
confignrpe
setservice nagios-nrpe-server start
invoke-rc.d nagios-nrpe-server start


##########Webmin############
configwebmin

##########Snort#############
setservice snort start

##########logcheck##########
#Nada a fazer, o .deb ja coloca o script no /etc/cron.d

#Cria rotas estaticas para a rede estadual
echo "route add -net 10.31.0.0 netmask 255.255.0.0 gw $REGW dev eth0" >> /etc/rcS.d/S99rungedai
echo "route add -net 172.30.0.0 netmask 255.255.0.0 gw $REGW dev eth0" >> /etc/rcS.d/S99rungedai
#log na tty12 (acertar isso depois)
echo -e  "\n*.* /dev/tty12\n" >> /etc/syslog.conf

##############################Finaliza########################
#derruba os daemons para serem carregados pela inicializacao
for x in squid postfix amavis clamav-daemon clamav-freshclam slapd bind9 snort ssh nscd webmin nagios-nrpe-server p3scan
do
	invoke-rc.d $x stop
done
########################################
# Alterando a senha de root
########################################
/usr/share/gconfig/autopasswd root $ROOTPW
ROOTPW="" 
saveconf ROOTPW
##################apt###################
cat <<eof >/etc/apt/sources.list
#deb file:///cdrom/ sarge main
deb ssh://ftp@repositorio.uniredemg.com.br/debian sarge main non-free
deb ssh://ftp@repositorio.uniredemg.com.br/unimedmg sarge main
deb ssh://ftp@repositorio.uniredemg.com.br/security sarge/updates main
eof
##################finalizacoes################
cp -f $root/etc/login.defs /etc
#rotinas cron
cp -f $root/etc/cron.daily/* /etc/cron.daily
#Configuracao do sargreports
cp -f $root/etc/webmin/sarg/* /etc/webmin/sarg
######################FIM###############
rm -f /tmp/config
