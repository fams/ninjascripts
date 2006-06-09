#!/usr/bin/env python
#
# Process Monitor - Monitor de Processos
# Scritp para monitorar se um processo estah ativo e 
# reinicia-lo caso necessario
# TODO: Implementar Tratamento dos erros
# TODO: Mudar funcionamento para daemon
# TODO: Criar Rotina para LOG em arquivos das reinicializacoes
#
# Originally written by: Paulo Lucio <plucio@linuxplace.com.br>
# Release: $Id: pmonitor.py

import os
import sys
import string
import smtplib
import commands
import dns.resolver

# Configuration
# Matriz nx2 com processo,servico a ser reiniciado
psm = [('postfix','postfix'),('amavisd','amavisd-new'),('mysql','mysql')]
# Lista com Emails a serem notificados em caso de problemas
notify = ('553178133027@page.nextel.com.br','paulo@linuxplace.com.br')

# Funcoes
def prompt(prompt):
    return raw_input(prompt).strip()

def checkprocess(processo):
    status = os.system('/bin/ps -ef|grep -v grep|grep ' + processo + ' 1>/dev/null')
    return status

def restart(processo):
    status = commands.getoutput('/etc/init.d/' + processo + ' restart')
    return status

def sendmail(email,msg):
    dominio=''
    smtpserver=''
    nome,dominio = email.split("@")
    if dominio == 'mgmaster.com.br':
        smtpserver='200.243.151.136'
    else:
        smtpserver=getmx(dominio)
    smtpserverc = smtplib.SMTP(str(smtpserver))
    smtpserverc.sendmail('monitor@mail.mgmaster.com.br', email, msg)
    smtpserverc.quit()

def getmx(dominio):
#    query = dns.message.make_query( dominio, dns.rdatatype.MX )
#    smtpserver = dns.query.tcp( query, '137.65.1.1',timeout=15 )
    try:
       temp = dns.resolver.query( dominio, 'MX' )
       smtpserver=[]
       for rdata in temp:
          smtpserver.append(rdata.exchange)
    except:
       smtpserver=[dominio]
    return smtpserver[0]

def mmessage(to,assunto,text):
    headers = "From: monitor@mail.mgmaster.com.br\r\nTo: %s\r\nSubject: %s\r\n\r\n" % (to,assunto)
    mensagem = headers + text 
    return mensagem
    

# Inicio
if __name__ == "__main__":
    for row in range(len(psm)):
        rc = checkprocess(psm[row][0])
        if rc != 0:
	   msg = ''
           msg = psm[row][0] + ' Nao estah carregado, executando: \r\n'
	   msg = msg + restart(psm[row][1])
	   for email in range(len(notify)):
	       msg2=''
	       msg2 = mmessage(notify[email],"ERRO: Servico %s Parado !!!",msg) % (psm[row][0])
	       sendmail(notify[email],msg2)

