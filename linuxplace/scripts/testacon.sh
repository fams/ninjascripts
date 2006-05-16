# Reconex√o velox/virtua
# necessario colocar no crond
# author: <fams@linuxplace.com.br>
# Version: $Id$

INETIFACE=eth1
PEER=$(route -n|grep $INETIFACE|grep ^0.0.0.0|awk '{print $2}')
OPERADORA=virtua
function reconecta(){
	case "$1" in
	"virtua")
		/sbin/shorewall clear
		ifdown $INETIFACE
		sleep 10
		ifup $INETIFACE
		/sbin/shorewall start
	;;
	"velox")
		/sbin/shorewall clear
		poff dsl-provider
		sleep 10
		pon dsl-provider
		/sbin/shorewall start
	;;
esac
}

if [ -z "$PEER" ];then
	reconecta $OPERADORA
fi
result=$(ping -w 10 $PEER | grep  "100% packet loss")
if [ ! -z "$result" ];then
	reconecta $OPERADORA
fi

