#!/bin/bash
getent passwd svccap >/dev/null
ret=$?
if [ $ret -ne 0 ];then
	echo "Nao existe usuario svccap"
fi
if [ ! -d /usr/local/share/linuxplace ]; then
	mkdir -p /usr/local/share/linuxplace
fi
if [ ! -d /usr/local/etc ]; then
	mkdir -p /usr/local/etc
fi
if [ ! -d /usr/local/share/doc/getkeys ]; then
	mkdir -p /usr/local/share/doc/getkeys
fi
if [ ! -d ~svccap/.ssh ];then
	group=$(getent passwd svccap|cut -f 4 -d: )
	mkdir -p ~svccap/.ssh
	chown svccap:$group ~svccap/.ssh
	cp share/authorized_linuxplace ~svccap/.ssh/authorized_keys2
fi

cp -pa doc/getkeys.conf.default /usr/local/etc
cp -pa share/* /usr/local/share/linuxplace
cp -pa doc/* /usr/local/share/doc/getkeys/

cp script/getkeys.sh /usr/local/sbin
cp script/extended.sh /usr/local/sbin
chmod +x /usr/local/sbin/{getkeys.sh,extended.sh}

echo -e "Lembre-se de configurar o cron.d, o exemplo está em /usr/local/share/doc/getkeys\nConfira se o /etc/sshd_config está apontando o authorized_keys para authorized_keys2\nConfigure o getkeys.conf a partir do default que está no /usr/local/etc, vc precisa de um numero de ninja"
