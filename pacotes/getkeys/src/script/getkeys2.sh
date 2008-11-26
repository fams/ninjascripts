#!/bin/bash

URL="https://192.168.0.2/update/extended2.php" 
XMLFILE=$(/bin/mktemp) 
#Header 
function XMLheader () {
    echo '<?xml version="1.0" encoding="UTF-8"?>
<gk version="1.1">
'
}
function XMLfooter () {
    echo "</gk>"
}
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
function XMLuptime () {
    echo -e "\t<uptime>"
    /usr/bin/uptime
    echo -e "\t</uptime>"
}
############Print XML##########
XMLheader >>$XMLFILE
XMLlast   >>$XMLFILE
XMLuptime >>$XMLFILE
XMLfooter >>$XMLFILE
cat $XMLFILE 
STR1=$(perl -pe 's/(\W)/"%".unpack"H2",$1/ge' $XMLFILE) 
curl -k -X POST -F teste=$STR1 $URL 
rm $XMLFILE 
