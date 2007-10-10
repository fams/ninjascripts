#!/usr/bin/perl 
#
# Acesso ao cmdserver linuxplace
# Sem documentação perl por enquanto
# Fique a vontade para contribuir
# Fernando Augusto Medeiros Silva  <fams@linupxlace.com.br>
# Copyright: Server Place LTDA
#
# Version $Id$
#
package lxnclient;
my $lxnCensus = 0;

use strict;
use POSIX qw(setsid);
use Net::SSH qw(sshopen2);


sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
        $lxnCensus++;
        $self->{USER}    = undef;
        $self->{HOST}    = undef;
        $self->{TIMEOUT} = 5;
        $self->{READER}  = \*READER;
        $self->{WRITER}  = \*WRITER;
        $self->{MSG}     = undef;
        bless ($self, $class);
        return $self;
}

sub connect{
    my $self = shift;
    $self->{USER} = shift;
    $self->{HOST} = shift;
    if ( not defined $self->{USER} || not defined $self->{HOST}) {
        return 0;
    }
    sshopen2($self->{USER}."\@".$self->{HOST}, $self->{READER}, $self->{WRITER}) ||  return 0;
}

##############
# remoteexec
# 
# executa procedimento remoto
# recebe o usuário remoto, o host remot, o comando a ser executado,
# referencia para a mensagem
# o retorno pode ser:
# 0  : nem um nem outro, erro interno de processamento
# 1  : funcionou
# 2  : problema
#
#
sub exec{
    my $self = shift;
    my $cmd = shift;
    $|=1;

    my $return = $self->waitfor("^cmd >");
    if ($return){
        $self->ipcchomp();
        local *WRITER =  $self->{WRITER}; 
        print WRITER "$cmd\n";
    }
    else{
        #referencia
        $self->{MSG} = "Nao recebi prompt ";
        return 0;
    }

    #Espera um erro aceitavel
    $return = $self->waitfor( "^(OK|ERR).*\n" );

    #limpa o buffer de leitura
    $self->ipcchomp();

    if ($return){
        my ( $status , @msg ) = split ( /:/ , $return );
        my $msg = join ( ":" , @msg );
        if( $status =~ 'OK') {
            $self->{MSG} = $msg;
            return 1;
        }
        else{
            $self->{MSG} = $msg;
            return 2;
        }
    }
    else{
        $self->{MSG} = "Resposta invalida do servidor ao executar $cmd";
        return 0;
    }
}
        

#################
# 
# Functions
#

sub waitfor{
    my ($self,$pattern) = @_;
    my $found;
    local *READER = $self->{READER};
    eval{
        my $char; 
        my $read;
        local $SIG{ALRM} = sub { 
                        $self->{MSG} = $read.$! ;
                        $found=0;
                        die "timeout\n";
        };
        alarm $self->{TIMEOUT};
        while( $char = "".getc READER ){
            alarm $self->{TIMEOUT};
            $read .= $char;
            #print $char,ord($char),"\n";
            #print $read;
            if( $read =~ /$pattern/ ){
            #    print "FOUND\n";
                $SIG{ALRM} = 'IGNORE';
                $found = $read;
                last;
            } 
        }
    };
#   print "fucked\n";
    $SIG{ALRM} = 'IGNORE';
    return $found ;
}
sub ipcchomp{
    my $self = shift;
    my $char;
    *READER = $self->{READER};
    eval{
        local $SIG{ALRM} = sub { 
             die"timeout\n";
        };
        alarm 2;
        while($char = "".getc READER){
            alarm 2;
        }
    };
    $SIG{ALRM} = 'IGNORE';
}
sub DESTROY {
    my $self = shift;
    $lxnCensus--;
    close $self->{READER};
    close $self->{WRITER};
}


1;
