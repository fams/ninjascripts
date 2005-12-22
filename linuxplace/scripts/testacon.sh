INETIFACE=eth1
PEER=$(route -n|grep $INETIFACE|grep ^0.0.0.0|awk '{print $2}')
function reconecta(){
	/sbin/shorewall clear
	ifdown $INETIFACE
	sleep 10
	ifup $INETIFACE
	/sbin/shorewall start
}

if [ -z "$PEER" ];then
	reconecta
fi
result=$(ping -w 10 $PEER | grep  "100% packet loss")
if [ ! -z "$result" ];then
	reconecta
fi

