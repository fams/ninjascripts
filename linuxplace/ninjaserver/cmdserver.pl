#!/usr/bin/perl -w -T
#
#Esse software tem como objetivo executar as chamadas do gerenciador ninja
#
#Fernando Augusto Medeiros Silva
#
#
#
#Version: $Id$
#
use Sys::Syslog;
use Config::IniFiles;
use File::Path;
use Net::LDAP;
use filetest 'access';


#Inicializacao
my $cfg = new Config::IniFiles( -file => "/usr/local/etc/cmdserver.ini" );
my $facility = $cfg->val( 'MAIN', 'logfacility' );
my $ldapuri = $cfg->val( 'MAIN', 'ldapuri' );
my $ldapuserdn = $cfg->val( 'MAIN' , 'ldapuserdn' );
my $ldappasswd = $cfg->val( 'MAIN' , 'ldappasswd' );
my $version = "0.1";

$|=1;

#conexao ldap
$ldap = Net::LDAP->new( $ldapuri ) or Err( "LDAP, $@" );
my $mesg = $ldap->bind( $ldapuserdn, 
            version =>3,
            password => $ldappasswd ) or Err( "LDAP $@");

#Security
$ENV{PATH}="/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/sbin:/usr/local/bin";

#syslog
openlog( 'cmdserver' , 'ndelay,pid' , $facility );

#
#jumptable e lista de commandos
#

my %commands = ( 
        "mksmbdir"      => \&mksmbdir,
        "mkmaildir"     => \&mkmaildir,
        "mkftpdir"      => \&mkftpdir,
        "vrfysmbdir"    => \&vfysmbdir,
        "vrfymaildir"   => \&vrfymaildir,
        "vrfyftpdir"    => \&vrfyftpdir,
        "version"    => \&version,
        "curdate"    => \&curdate,
        "help"    => \&help,
        );

my %cmdhelp = (
    "mksmbdir" =>   "mksmbdir USERID <forcechown>\n USERID: userid of user\n forcechown: chown directory to user\n",
);




########################################   Programs starts here  ################################

#print cmdprompt
print "cmd >";
while($line=<STDIN>){
    if ( $line =~ /^$/ ) {
        print "cmd >";
        next;
    }
    chomp $line;
    my($cmd,@params)=split(/ /,$line);

#primeiro vemos se está saindo
    if($cmd eq "exit" or $cmd eq "quit" ){
        print "Bye\n";
        _shutdown();
        exit 0;
    }

#chama a função da jumptable
    if( defined($commands{$cmd}) ) {
        &{$commands{$cmd}}( @params );
    }
    else {
        print "Invalid command $line\n";
        print "Valid commands are:\n";
        foreach $command ( sort keys %commands ) {
            print "\t$command\n";
        }
    }
    print "cmd >";
}



################functions#########################

sub data {
    print "aqui vai a data\n";
}

sub version {
    print "CmdServer: $version\n";
}

sub mkftpdir {
    my ( $userid , $chown ) = @_;
    $chown = defined($chown) ? 
                $chown 
                : 1;
    local %ret = getuserattr( $userid , "FTPdir" );    
    if ( ! defined $ret{'FTPdir'} ){
        Err("Nao encontrei FTPdir para o usuario");
    }        
    return mksecdir( 'FTP' , $ret{'FTPdir'} , $userid , $chown );
}

sub mksmbdir {
    my( $userid , $chown ) = @_;
    $chown = defined($chown) ? 
                $chown 
                : 1;
    local %ret = getuserattr( $userid , "homeDirectory" );    
    if ( ! defined $ret{'homeDirectory'} ){
        Err("Nao encontrei homeDirectory para o usuario");
    }        
    return mksecdir( 'SMB', $ret{'homeDirectory'} , $userid , $chown );
}

sub mkmaildir {
    my( $userid , $chown ) = @_;
    $chown = defined($chown) ? 
                $chown 
                : 1;
    local %ret = getuserattr( $userid , "mailMessageStore" );    
    if ( ! defined $ret{'mailMessageStore'} ){
        Err("Nao encontrei mailMessageStore para o usuario");
    }
    mksecdir( 'MAIL', $ret{'mailMessageStore'} , $userid , $chown );
    local $maildir = $ret{'mailMessageStore'} ;
    eval { mkpath([ "$maildir/new" ,
                    "$maildir/cur" ,
                    "$maildir/tmp" , ] , 
                    0 ,
                    0700 )
    };
    if ($@) {
          Err( "MKDIR: Erro criando maildir $maildir" );
    }
    if ( $userid =~ /^([a-z0-9\.]+)$/) {
        $userid = $1;
    }
    else{
        Err("Lixo de entrada! guardando essa tentativa em log!!!\n");
    }
    system( "/bin/chown $userid:100 $maildir/new" ) == 0  
        or Err( "Erro chown $userid:100 $maildir/new:" );
    system( "/bin/chown $userid:100 $maildir/cur" ) == 0
        or Err( "Erro chown $userid:100 $maildir/cur:" );
    system( "/bin/chown $userid:100 $maildir/tmp" ) == 0
        or Err( "Erro chown $userid:100 $maildir/tmp:" );
    return 1;
}
sub vrfysmbdir {
    my ($userid) = @_;
    local %ret = getuserattr( $userid , "homeDirectory" );
    if ( ! defined $ret{'homeDirectory'} ){
        Err("Nao encontrei homeDirectory para o usuario");
    }
    Info( "smbdir status is: ".vrfyuserdir($userid,$ret{"homeDirectory"}));
}
sub vrfyftpdir {
    my ($userid) = @_;
    local %ret = getuserattr( $userid , "FTPdir" );
    if ( ! defined $ret{'FTPdir'} ){
        Err("Nao encontrei FTPdir para o usuario");
    }
    Info( "ftpdir status is: ".vrfyuserdir($userid,$ret{"FTPdir"}));
}
sub vrfymaildir {
    my ($userid) = @_;
    local %ret = getuserattr( $userid , "mailMessageStore" );
    if ( ! defined $ret{'mailMessageStore'} ){
        Err("Nao encontrei mailMessageStore para o usuario");
    }
    Info( "maildir status is: ".vrfyuserdir($userid,$ret{"mailMessageStore"}));
}
sub vrfyuserdir {
    my ($userid, $dir ) = @_;
    my $uid = getpwnam($userid);
    my $ret = 0;
    my $restore	= $>;
    $>=$uid;
    if ( -e $dir ){ $ret+=1; }
    if ( -d $dir ){ $ret+=2; }
    if ( -r $dir ){ $ret+=4; }
    if ( -w $dir ){ $ret+=8; }
    $>=$restore
    return $ret;
}
###################################
# Secure mkdir
#
sub mksecdir {
    my ( $pathtype , $path , $userid , $chown ) = @_ ; 
    if ( ( ! defined $path) || ( ! defined $pathtype ) || ( ! defined $userid ) ) {
        Err("Parâmetros insuficientes para mksecdir $pathtype:$path:$userid");
    }
    chomp $path ;
    chomp $userid;
    chomp $chown;

    if ( $chown =~ /^[0-9]$/ ) {
        $chown = ( $chown ne 0 ) ? 1 : 0;
    }
    else{
         Err("Lixo de entrada! logando $chown");
    }
    if ( $userid=~ /[^a-z0-9\.]/) {
        Err("Lixo de entrada! guardando essa tentativa em log!!!");
    }
    if( $path =~ /^[^\/]/  ) {
        Err("Lixo de entrada o caminho $path nao comeca com /");
    }
    #so pode entrar usuário bem definido
    if ( $path =~ m/^([A-Za-z0-9\.\-\/]+$)/ ){ 
        $path = $1;
    }
    else{
        Err("Lixo de entrada! logando $path");
    }
    if( $path =~ m/\.\./ ) { 
        Err("Lixo de entrada! Tentativa de '..' logando $path");
    }
    my ( $basedir ) = $cfg->val( $pathtype , 'basedir' );
    $basedir =~ s/ //g;
    $basedir =~ s/\/$//;
    $basedir .= "/";
    my $baselen = length( $basedir );
    if( substr( $path, 0 , $baselen ) eq $basedir ){
        if ( ! -d $path){
            eval { mkpath([ "$path"], 0 , 0711 ) };
            if ($@) {
                Err("Erro ao criar o caminho $pathtype: $@");
            }
        }
        if( $chown eq 1 ) {
            my ($login,$pass,$uid,$gid) = getpwnam($userid)
                or Err("$userid not in passwd file");
    #checking taind vars
            if($uid =~ m/^([0-9]+)$/){
                $uid=$1;
            }
            else{
                Err("Lixo de entrada! logando. $uid");
            }
            if($gid =~ m/^([0-9]+)$/){
                $gid=$1;
            }
            else{
                Err("Lixo de entrada! logando. $uid");
            }
            unless( chown $uid , $gid ,  $path ) {
                Err("Erro ao definir dono de $path: $uid , $gid $@");
            }
        }# if chown 1
        Info("criado $pathtype userid:$userid path:$path chown:$chown");
    }
    else{
        Err("substr( $path , \0 , $baselen -1 ) ne $basedir");
    }
    return 1;
}

#Erro
#Log de erro para o syslog
sub logg {
    my( $level , $mesg ) = @_ ;
    syslog( $level , "cmdserver: ".$mesg );
}

#Sai do sistema com erro
sub  Err {
    my( $errmsg ) = @_;
    logg( "warning" , $errmsg );
    print "ERR: $errmsg\n" ;
    _shutdown();
    exit 1;
} 

#Retorna para o usuário e para o syslog
sub Info {
    my( $infomsg ) =@_;
    logg( "notice" , $infomsg );
    print "OK: $infomsg \n"; 
}

#Pega attributo do usuario
sub getuserattr {  
    my($userid,$attr)= @_;
    my @attrs = split(/,/, $attr);
   # %commands = map { $_ , 1} @commands;
    my $ldapsuffix = $cfg->val( 'MAIN' , 'ldapsuffix' );
    my $result = $main::ldap->search( # perform a search
                base   => $ldapsuffix ,
                filter => "(&(uid=$userid)(objectClass=posixAccount))" ,
                scope  => 'sub' ,
                attrs  => @attrs,
               );
#    $result->code && Err($mesg->error);
    if ($result->count > 1) {
       Err("LDAP: mais de um objeto encontrado para userid: $userid");
    }
    if ($result->count < 1) {
       Err("LDAP: nenhum objeto encontrado para userid: $userid");
    }
    my $user = $result->shift_entry;
    my %rattrs = ();
    foreach my $attr ($user->attributes) {
        $rattrs{$attr} = $user->get_value($attr);
    } 
    return %rattrs;

}
sub help {
    my ( $cmd ) = @_;
    if ( defined $cmd ) {
        print $cmdhelp{$cmd}."\n";
    }
    else {
        print "Valid commands are:\n";
        foreach $command ( sort keys %commands ) {
            print "\t$command\n";
        }
        print "OK\n";
    }
}

sub _shutdown{
    $main::ldap->unbind();
}
