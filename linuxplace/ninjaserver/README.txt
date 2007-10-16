###########

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
