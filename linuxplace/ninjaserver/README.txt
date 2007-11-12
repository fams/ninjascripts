###########

Instalar o perl suid
perl-suid

para funcionar o cmdserver precisa dos seguintes modulos perl

Config::IniFiles    -> libconfig-inifiles-perl
Net::LDAP           -> libnet-ldap-perl
Proc::UID           -> CPAN


Do lado do idx os seguintes além dos já conhecidos
Net::SSH            -> libnet-ssh-perl

as configuracoes novas no idxldapaccounst são:
remotemail
remoteunix
remotesmb
remoteftp

todas se referem à máquina onde estará o servidor em questao
se for local, favor colocar localhost

o usuario execscript deve ser criado, o seu home apontado para /var/lib/cmdserver
crie esse homedir e coloque a chave publica do servidor webmin (gerado via ssh)
o root tem de ter direito de logar sem senha nesse usuário e o scrip tem de estar suid, 

ex:
#--corte daqui
  groupadd -g 999 execscript
  useradd -g execscript -m -d /var/lib/cmdserver -s /usr/local/linuxplace/ninjaserver/cmdserver.pl execscript
  echo "/usr/local/linuxplace/ninjaserver/cmdserver.pl" >> /etc/shells 
  #editar o arquivo de shells validos (/etc/shells)"
  chown :execscript /usr/local/linuxplace/ninjaserver/cmdserver.pl
  chmod 740 /var/lib/cmdserver
  chmod u+s /usr/local/linuxplace/ninjaserver/cmdserver.pl
  su - execscript -s /bin/bash -c 'ssh-keygen -t dsa'
  mv /var/lib/cmdserver/.ssh/id_dsa.pub /var/lib/cmdserver/.ssh/authorized_keys2
#-- corte ate aqui



Copiar o arquivo /var/lib/cmdserver/.ssh/id_dsa para o servidor que contem o webmin como /root/.ssh/id_dsa"
  #rm -f /var/lib/cmdserver/.ssh/id_dsa
  #
Configure o cmdserver copiando o cmdserver.conf para o /usr/local/etc/
os parametros dele sao:

[MAIN]
logfacility=local0
;uri para acesso ao ldap 
;ex: ldap://localhost
ldapuri=ldap://192.168.0.2
;manager da base
ldapuserdn=cn=manager,dc=linuxplace,dc=intra
;password do manager
ldappasswd=teste
;sufixo da base
ldapsuffix=dc=linuxplace,dc=intra

[SMB]
;diretorio base dos homedir
basedir=/home/samba/usuarios/

[FTP]
;diretorio base dos ftp
basedir=/home/usuarios/

[MAIL]
diretorio base dos emails
basedir=/home/usuarios/

