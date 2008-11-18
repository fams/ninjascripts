#!/bin/sh
# Atualizacao de chaves
# necessario colocar no crond
# author: <fams@linuxplace.com.br>
# Version: $Id: getkeys.sh,v 1.11 2007-07-26 14:21:18 plucio Exp $

#origem
if [ -z "$1" ];then
	conf=/usr/local/etc/getkeys.conf
else
	conf=$1; 
fi
if [ -f $conf ];then
	. $conf
else 
	echo "Sem configuracao"
	exit 1
fi
for x  in $GPG $TAR $CURL ;do 
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

if  [ ! -d $homedir ];then 
  useradd $user
  mkdir $homedir
  chown $user.$group  $homedir -R
fi
if  [ ! -d $homedir/.ssh ];then 
  mkdir $homedir/.ssh
  chown $user.users   $homedir/.ssh 
fi
cd $homedir/.ssh
#Fazendo download das chaves
tmpdir=$(mktemp -d chaveXXXXXX)
cd $tmpdir
$CURL -s -f $host/update/getkey.php?host=$ninja\&username=$user > bundle.tar 
saida=$?
if [ $saida -ne 0 ];then 
	echo "Erro obtendo chaves" 
	rm -f bundle.tar
	/bin/rm -Rf $tmpdir
	exit 1
fi
if [ -f ../bundle.tar ];then    
    cmp ../bundle.tar bundle.tar >/dev/null
    saida=$?
    if [ $saida -eq 0 ];then
        rm -f bundle.tar
        rm -Rf $homedir/.ssh/$tmpdir
        exit 0
    fi
fi
$TAR -xvf bundle.tar >/dev/null
for x in *asc;do
    checksig $x
done
cp $linuxplace/update/authorized_linuxplace authorized_keys2
for x in $(ls *pub|sort -n);do
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
