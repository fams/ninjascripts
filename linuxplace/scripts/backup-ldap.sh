#!/bin/bash
#
# Script para Backup da Base Ldap
#

STOP_BEFORE_BAK=1

umask 077
SLAPCAT="/usr/sbin/slapcat"
BACKHOME="/var/backups"
INITSCRIPT="/etc/init.d/ldap"


if [ "$STOP_BEFORE_BAK" -eq "1" ];then
	$INITSCRIPT stop
fi
sleep 1
$SLAPCAT > $BACKHOME/backup-ldap-$(date +%Y%m%d).ldif
/usr/bin/find $BACKHOME -type f -regex .*ldif$ -mtime +365 -exec rm -f {} \;
sleep 1
if [ "$STOP_BEFORE_BAK" -eq "1" ];then
	$INITSCRIPT start
fi
