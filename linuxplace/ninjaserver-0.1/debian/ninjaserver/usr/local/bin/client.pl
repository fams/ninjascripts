#!/usr/bin/perl
#
# Exemplo de cliente para ser integrado
#
# Sem documentação perl por enquanto
# Fique a vontade para contribuir
# Fernando Augusto Medeiros Silva  <fams@linupxlace.com.br>
# Copyright: Server Place LTDA
#
# Version: $Id: client.pl,v 1.2 2007-11-03 22:59:12 fams Exp $
#
#

use lxnclient;

$nomade = new lxnclient;

if ($nomade->connect("execscript","localhost")){
    $nomade->exec("mksmbdir fams 1");
    print $nomade->{MSG};
}
else{
    print $nomade->{MSG};
    print "droga :(\n";
}
