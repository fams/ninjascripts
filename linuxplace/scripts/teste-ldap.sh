#!/bin/bash
#
# Script para teste/recovery da base LDAP
#
#Este comentario foi adicionado para mostrar ao Sergio

umask 077
BACKHOME="/var/backups"
INITSCRIPT="/etc/init.d/ldap"
TESTEDN="uid=root,ou=People,dc=grupounitas,dc=net"
TESTE=`ldapsearch -x -LLL|grep "$TESTEDN"|cut -d":" -f 2`
if [ -z $TESTE ]; then
	$INITSCRIPT restart
	echo "reiniciei " `date +"%d-%m-%Y %H:%M:%s"` >> /var/log/testeldap
	sleep 10
	TESTE=`ldapsearch -x -LLL|grep "$TESTEDN"|cut -d":" -f 2`
	if [ -z $TESTE ]; then
		DATA_ATUAL=`date -I`
		HORA_ATUAL=`date +%T`
		tar czf $BACKHOME/base_backup_ldap_$DATA_ATUAL-$HORA_ATUAL$.tar.gz
        	db_recover -v -h /var/lib/ldap >> /var/log/db_recover_log
        	$INITSCRIPT start
		echo "Recovery " `date +"%d-%m-%Y %H:%M:%S"` >> /var/log/testeldap
	fi
fi
ps -ef|grep db_chec|grep -v grep
ret=$?
if [ $ret -ne 0 ];then
	db_checkpoint -h /var/lib/ldap/ -p 5 -L /var/log/check_point.log &
fi
