#!/bin/bash
#
# Script para Backup da Base Ldap
#

umask 077
SLAPCAT="/usr/sbin/slapcat"
BACKHOME="/var/backup"


/etc/init.d/slapd stop
sleep 1
$SLAPCAT > $BACKHOME/backup-ldap-$(date +%Y%m%d).ldif
/usr/bin/find $BACKHOME -type f -regex .*ldif$ -mtime +365 -exec rm -f {} \;
sleep 1
/etc/init.d/slapd start
