#!/bin/bash
# Paulo Lucio <paulo@linuxplace.com.br>
# $Id$

if [ -z $1 ]; then
	echo "Favor informar o nome do usuario a editar vacation"
	echo "ex.: $0 usuario"
	exit 0
fi

if [ -z $(getent passwd $1) ]; then
	echo "Usuario $1 nao encontrado no sistema"
fi

usuario="$1"
vac_homedir=$(getent passwd $1 |cut -d : -f 6)

if [ -f $vac_homedir/.forward ]; then
	vac_active="yes"	
else
	vac_active="no"
fi

clear
echo "************* EDICAO VACATION PARA USUARIO $usuario ***********"
echo -e '\n\n'
echo  "Informe a opcao desejada: "
echo  "(1) Criar vacation para usuario $usuario"
echo  "(2) Editar vacation para usuario $usuario"
echo  "(3) Remover vacation para usuario $usuario"
echo  "(4) Sair"
echo -e '\n'
read -n1 -p "opcao: " opcao
echo 

case "$opcao" in
	1)
		if [ "$vac_active" == "yes" ]; then
			echo "Opcao invalida !!!"
			echo "Vacation já se encontra ativo"
			echo "escolha outra opcao"
			exit 1
		fi
		/usr/bin/vacation -z -r 0 -I $usuario
		echo "\\$usuario \"|/usr/bin/vacation -z -j $usuario"\" > $vac_homedir/.forward
		echo "Subject: Resposta Automatica" > $vac_homedir/.vacation.msg
		echo -e '\n'>> $vac_homedir/.vacation.msg
		mcedit $vac_homedir/.vacation.msg
		chown $usuario $vac_homedir/.vacation.msg
		chown $usuario $vac_homedir/.vacation.db
		chown $usuario $vac_homedir/.forward
		echo "Vacation criado com sucesso para usuario $usuario"
	;;
	2)
		if [ "$vac_active" == "no" ]; then
			echo "Opcao invalida !!!"
			echo "Vacation nao ativo para usuario $usuario"
			echo "escolha outra opcao"
			sleep 3
			exit 1
		fi
		mcedit $vac_homedir/.vacation.msg
		echo "Edicao concluida!!"
	;;
	3)
		if [ "$vac_active" == "no" ]; then
			echo "Opcao invalida !!!"
			echo "Vacation nao ativo para usuario $usuario"
			echo "escolha outra opcao"
			sleep 3
			exit 1
		fi
		rm -f $vac_homedir/.forward
		rm -f $vac_homedir/.vacation.db
		echo "Vacation removido para usuario $usuario"
	;;
	4)
		exit 0
	;;
	*)
		echo "Opcao invalida!!!"
	;;
esac
