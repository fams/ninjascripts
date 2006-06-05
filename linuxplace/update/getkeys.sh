#!/bin/sh
# Atualizacao de chaves
# necessario colocar no crond
# author: <fams@linuxplace.com.br>
# Version: $Id$

GPG=/usr/bin/gpg
#origem
host="http://ninja.linuxplace.com.br"
ninja=0001

#verifica se a chave foi modificada
check_new(){
diff $1 $2>/dev/null
saida=$?
case $saida in
	0)
	exit 0 
	;;
	1)
	;;
	*)
	echo Erro comparando arquivos
	exit 1
	;;
esac

}
if  [ ! -d ~svccap/.ssh ];then 
  mkdir ~svccap/.ssh
  chown svccap.users   ~svccap/.ssh 
fi
cd /home/svccap/.ssh
#Fazendo download das chaves
curl -f $host/keys/$ninja/authorized_keys2.asc -o asc.tmp
saida=$?
if [ $saida -ne 0 ];then 
	echo "Erro obtendo chaves" 
	rm -f asc.tmp
	exit 1
fi
check_new authorized_keys2.asc asc.tmp

rm -f authorized_keys2.tmp
$GPG -o authorized_keys2.tmp asc.tmp
if [ $? -ne 0 ];then
	echo "Arquivo Inválido!!!"
	mail -s "Arquivo inválido de chave" root@localhost <authorized_keys2.asc
	exit 1
fi
mv authorized_keys2.asc authorized_keys2.asc.old
mv asc.tmp authorized_keys2.asc
mv authorized_keys2 authorized_keys2.old
mv authorized_keys2.tmp authorized_keys2
chown svccap.svccap authorized_keys2
