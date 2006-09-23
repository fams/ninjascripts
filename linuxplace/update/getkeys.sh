#!/bin/sh
set -x 
# Atualizacao de chaves
# necessario colocar no crond
# author: <fams@linuxplace.com.br>
# Version: $Id$

GPG=/usr/bin/gpg
#origem
host="http://dotproject.linuxplace.com.br"
ninja=1
homedir="/home/svccap"
linuxplace="/usr/local/linuxplace"

#verifica se a chave foi modificada
checksig(){
gpg --homedir $linuxplace/update/gpg -o $(echo $x |sed 's/\.asc//') $1
saida=$?
case $saida in
	0)
    return 0
	;;
	*)
    echo "Chave Invalida!!"
    exit 1
	;;
esac
}

if  [ ! -d ~svccap ];then 
  useradd svccap
  mkdir /home/svccap
  chown svccap.users  ~svccap/ -R
fi
if  [ ! -d ~svccap/.ssh ];then 
  mkdir ~svccap/.ssh
  chown svccap.users   ~svccap/.ssh 
fi
cd /home/svccap/.ssh
#Fazendo download das chaves
tmpdir=$(mktemp -d chaveXXXXXX)
cd $tmpdir
curl -f $host/update/getkey.php?host=$ninja > bundle.tar
if [ -f ../bundle.tar ];then    
    cmp ../bundle.tar bundle.tar
fi
saida=$?
if [ $saida -ne 0 ];then 
	echo "Erro obtendo chaves" 
	rm -f bundle.tar
	exit 1
fi
tar -xvf bundle.tar
for x in *asc;do
    checksig $x
done
cp $linuxplace/update/authorized_linuxplace auhtorized_keys2
for x in $(ls *pub|sort);do
    cat $x >>authorized_keys2
done
cd $homedir/.ssh
rm bundle.tar.old
mv bundle.tar bundle.tar.old
mv $tmpdir/bundle.tar .
rm authorized_keys2.old
mv authorized_keys2 authorized_keys2.old
mv $tmpdir/authorized_keys2 authorized_keys2
chown svccap.users authorized_keys2
rm -Rf $tmpdir
