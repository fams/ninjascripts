#!/usr/bin/env python

import os
import re
import sys
import socket
import shutil

# Pega o FQDN do servidor para usar no myhostname
PFHOSTNAME = socket.getfqdn()

# Base do Configurador
LXBASE="/usr/local/linuxplace"

# Configuracoes a serem obtidas do Config
PFMYNETWORK="192.168.1.0/24"
LDAPHOST="127.0.0.1"
LDAPBASEDN="dc=veterinaria,dc=intra"
LDAPBINDPW="teste"
SMTPRELAY="N"
PFRELAYHOST="smtp.bhz.terra.com.br"
PFRELAYUSER="veterinaria"
PFRELAYPASS="a4g9h3e7"

# Configuracoes de seguranca (Nao alterar caso nao saiba do que se trata)
UNCOMMENTLINES="N"

#Configuracoes Inalteraveis
srcfile = LXBASE + "/stanza/postfix/main.cf"
dstfile = "/etc/postfix/main.cf"

#
LDAPBINDDN="cn=proxyuser,ou=Staff," + LDAPBASEDN

# Le o arquivo stanza
if os.path.exists(srcfile):
	fp = open(srcfile,"r")
else:
	print "CANNOT OPEN STANZA FILE. ATUALIZE O REPOSITORIO!"

stanza = fp.readlines()
fp.close()

# Abre o arquivo a ser gerado
fp = open(dstfile,"w")

#Faz as substituicoes necessarias
for line in stanza:
	newline=re.sub("%HOSTNAME%",PFHOSTNAME,line)
	newline=re.sub("%MYNETWORK%",PFMYNETWORK,newline)
	newline=re.sub("%LDAPHOST%",LDAPHOST,newline)
	newline=re.sub("%LDAPBASEDN%",LDAPBASEDN,newline)
	newline=re.sub("%LDAPBINDDN%",LDAPBINDDN,newline)
	newline=re.sub("%LDAPBINDPW%",LDAPBINDPW,newline)
	if ( SMTPRELAY == "Y" ):
		if ( re.search("^###START-SMTPGATEWAYRELAY###$",newline)):
			UNCOMMENTLINES="Y"
		if ( re.search("^###END-SMTPGATEWAYRELAY###$",newline)):
			UNCOMMENTLINES="N"
		newline=re.sub("%RELAYHOST%",PFRELAYHOST,newline)
		newline=re.sub("%RELAYUSER%",PFRELAYUSER,newline)
		newline=re.sub("%RELAYPASS%",PFRELAYPASS,newline)
	if ( UNCOMMENTLINES == "Y" ):
		newline=re.sub("^#","",newline)
	fp.write(newline)
	

# Fecha o arquivo gerado
fp.close()

#Copia master.cf, ainda temos que mexer muito nesse script
shutil.copyfile( LXBASE + "/stanza/postfix/master.cf","/etc/postfix/master.cf")

os.system("/usr/bin/maildirmake /etc/skel/Maildir")
sys.exit(0)
