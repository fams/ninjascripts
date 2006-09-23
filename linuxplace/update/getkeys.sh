#!/bin/sh
# Atualizacao de chaves
# necessario colocar no crond
# author: <fams@linuxplace.com.br>
# Version: $Id$

#origem
host="http://dotproject.linuxplace.com.br"
ninja=1
homedir="/home/svccap"
linuxplace="/usr/local/linuxplace"
user=svccap
group=users
#caminhos
GPG=/usr/bin/gpg
TAR=/bin/tar
CURL=/usr/bin/curl
for x GPG TAR CURL ;do 
    if [ ! -f $x ];then
        echo $x nao encontrado!
        exit 1
    fi
done
#verifica se a chave foi modificada
checksig(){
$GPG  --no-permission-warning --no-tty --homedir $linuxplace/update/gpg -o $(echo $x |sed 's/\.asc//') $1  >/dev/null 2>&1
saida=$?
case $saida in
	0)
    return 0
	;;
	*)
    echo "Chave $1 Invalida!!"
    exit 1
	;;
esac
}

if  [ ! -d ~$user ];then 
  useradd $user
  mkdir /home/$user
  chown $user.$group  ~$user/ -R
fi
if  [ ! -d ~$user/.ssh ];then 
  mkdir ~$user/.ssh
  chown $user.users   ~$user/.ssh 
fi
cd /home/$user/.ssh
#Fazendo download das chaves
tmpdir=$(mktemp -d chaveXXXXXX)
cd $tmpdir
$CURL -s -f $host/update/getkey.php?host=$ninja > bundle.tar 
saida=$?
if [ $saida -ne 0 ];then 
	echo "Erro obtendo chaves" 
	rm -f bundle.tar
	exit 1
fi
if [ -f ../bundle.tar ];then    
    cmp ../bundle.tar bundle.tar >/dev/null
    saida=$?
    if [ $saida -eq 0 ];then
        rm -f bundle.tar
        cd /home/$user/.ssh/$tmpdir
        exit 0
    fi
fi
$TAR -xvf bundle.tar >/dev/null
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
chown $user.$group authorized_keys2
rm -Rf $tmpdir
