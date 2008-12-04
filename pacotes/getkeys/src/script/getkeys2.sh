#!/bin/bash
##################################################
#getkeys2.sh	  			         #
#Por Pedro S. Bizzotto <pedro@Linuxplace.com.br> #
#e Fernando A. M. Silva <fams@linuxplace.com.br> #
#Programa para enviar dados sobre um Ninja 	 #
##################################################

#Variaveis
#URL para envio do XML
export LANG=C
URL="https://192.168.0.2/update/extended2.php"
#Arquivos temporarios, XML e saída do apt-get -s 
XMLFILE=$(/bin/mktemp)
APTFILE=$(/bin/mktemp)
#CFGFILE do getkeys, usado só pra pegar o numero do ninja
CFGFILE="/usr/local/etc/getkeys.conf"
. $CFGFILE
NINJA=$ninja
#Header do XML
function XMLheader () {
    echo '<?xml version="1.0" encoding="UTF-8"?>
<gk version="1.1">
'
}
#Footer do XML
function XMLfooter () {
    echo "</gk>"
}
#Pega os 5 ultimos logins e formata pro XML
function XMLlast () {
    echo -e "\t<last>"
    while read LAST;do
        LASTUSER=$(echo $LAST|cut -f 1 -d" ") 
        LASTLOGON=$(echo $LAST|cut -f 6 -d" ") 
        LASTSEP=$(echo $LAST|cut -f 7 -d" ")
	case $LASTSEP in
		'-') 
        	LASTLOGOFF=$(echo $LAST|cut -f 8 -d" ")
		;; 
		'still')
		LASTLOGOFF='LOGADO'
		;;
		*)
		LASTLOGOFF='ERRO'
		;;
	esac
        echo -e "\t\t<loginentry user=\"$LASTUSER\" logon=\"$LASTLOGON\"
logoff=\"$LASTLOGOFF\" />"
    done < <(/usr/bin/last -n 5 -R|grep -v "^$"|grep -v ^wtmp)
    echo -e "\t</last>"
}
#Pega o uptime e formata pro XML
function XMLuptime () {
    echo -e "\t<uptime>"
    /usr/bin/uptime
    echo -e "\t</uptime>"
}
#pega o numero de pacotes atualizaveis e informacoes sobre
#os mesmos
function XMLpackages () {
    apt-get -s upgrade > $APTFILE 2>&1
    UPDATABLES=$(cat $APTFILE |grep upgraded| grep -v following |cut -d' ' -f 1)
    if [ -z "$UPDATABLES" ]; then
	UPDATABLES="ERRO"
    fi
    echo -e "\t<software updatables=\"$UPDATABLES\">"
    while read PACKLIST; do
	PACKAGE=$(echo $PACKLIST|grep Inst| sed -e "s/^Inst //")
	if [ -n "$PACKAGE" ]; then
	    echo -e "\t\t<package val=\"$PACKAGE\" />"
	fi
    done < <(cat $APTFILE)
    echo -e "\t</software>"
}
#Pega versao do kernel e da distro
function XMLversions () {
	KERNVERSION=$(uname -r)
	#Testa lsb-release
	if [ -f "/etc/lsb-release" ]; then
		. /etc/lsb-release
		DISTROVERSION=$DISTRIB_DESCRIPTION
	#senao, testa debian
	elif [ -f "/etc/debian_version" ]; then
		DISTROVERSION="Debian "$(cat /etc/debian_version)
	fi
	if [ -z "$DISTROVERSION" ]; then
		echo -e "\t<ninja id=\"$NINJA\" kernel=\"$KERNVERSION\" distro=\"ERRO\" />"
	else
		echo -e "\t<ninja id=\"$NINJA\" kernel=\"$KERNVERSION\" distro=\"$DISTROVERSION\" />"
	fi
}
	 
############Print XML##########
XMLheader   >>$XMLFILE
XMLversions >>$XMLFILE
XMLlast     >>$XMLFILE
XMLuptime   >>$XMLFILE
XMLpackages >>$XMLFILE
XMLfooter   >>$XMLFILE
#para debug
cat $XMLFILE
#URLencode
STR1=$(perl -pe 's/(\W)/"%".unpack"H2",$1/ge' $XMLFILE)
#faz o post do XML 
curl -k -X POST -F extended=$STR1 $URL
#Limpa temporarios 
rm $XMLFILE
rm $APTFILE
