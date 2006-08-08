#!/usr/bin/perl -w
my $userdn="ou=People,dc=grupounitas,dc=net";
my $groupdn="ou=Groups,dc=grupounitas,dc=net";
my $homebase="/home/";
my $servidor="master";
my $SID="S-1-5-21-4246911406-2831693534-103754718";
#my $ou="People";
my $desc="System User";
my $gecos="System User";
my $PwdLastSet="1100544816";
my $ou="unitas";

my @groupbypass = (
"root",
"bin",
"daemon",
"sys",
"adm",
"tty",
"disk",
"lp",
"mem",
"kmem",
"wheel",
"mail",
"news",
"uucp",
"man",
"games",
"gopher",
"dip",
"ftp",
"lock",
"nobody",
"users",
"rpm",
"floppy",
"vcsa",
"cluster",
"utmp",
"slocate",
"nscd",
"sshd",
"rpc",
"rpcuser",
"nfsnobody",
"mailnull",
"smmsp",
"pcap",
"xfs",
"ntp",
"gdm",
"desktop",
"apache",
"named",
"ldap",
"netdump",
"hpsmh",
"haclient",
"hacluster",
"cluster",
"dba",
"oinstall",
"dba",
"guest",
"nx"
);


my @bypass = (
"root",
"bin",
"daemon",
"adm",
"lp",
"sync",
"shutdown",
"halt",
"mail",
"news",
"uucp",
"operator",
"games",
"gopher",
"ftp",
"nobody",
"rpm",
"vcsa",
"nscd",
"sshd",
"rpc",
"rpcuser",
"nfsnobody",
"mailnull",
"smmsp",
"pcap",
"xfs",
"ntp",
"gdm",
"desktop",
"apache",
"named",
"ldap",
"netdump",
"hpsmh",
"hacluster",
"cluster",
"oracle",
"fams",
"rctec",
"luiz.gustavo",
"dalva",
"hacluster");

open(PASSWD,"</etc/passwd");
open(SHADOW,"</etc/shadow");
open(SMBPASSWD,"</etc/samba/smbpasswd");
open(GROUP,"</etc/group");

my %passwd = {};
my %group = {};
my %shadow = {};
my %smbpasswd = {};
my %hbypass = {};
my %gbypass = {};
my %groupmap = {};

sub geragroup{
    my($gid,$gidnumber,$members)=@_;
    my $rgid=($gidnumber*2+1000);
    $groupmap{$gidnumber}=$rgid;
    print <<eof
dn: cn=$gid,$groupdn
objectClass: posixGroup
objectClass: sambaGroupMapping
gidNumber: $gidnumber
cn: $gid
description: System Group
sambaSID: $SID-$rgid
sambaGroupType: 2
displayName: $gid
eof
;
foreach (@{ $members }){
    if(! /^$/){
        print "memberUid:$_\n";
    }
}
print "\n";


}

sub gerauser{
    my ($uid)=@_;
    my ($uidnumber,$gidnumber,$lixo,$home,$shell)=@{$passwd{$uid}};
    my ($userPassword,@lixo)=@{$shadow{$uid}};
    my ($lixo,$LMPASS,$NTPASS,$AccFlags,$changetime)=@{$smbpasswd{$uid}};
    my $ruid=($uidnumber*2+1000);
    my $rgid=($gidnumber*2+1000);
    my $cn = $uid;
    $cn =~ s/\./ /;
    $cn =~ s/\b(\w+)\b/ucfirst($1)/ge;    
    $sn =$cn;
    $sn =~ s/.* (\w+)\b$/$1/;
    if($userPassword=~ m/!!/){ $userPassword="XXXXXXXXXXXXXXXXXXX" ;}
    if($NTPASS=~ m/!!/){ $NTPASS="XXXXXXXXXXXXXXXXXXX" ;}
    if($AccFlags=~ m/!!/){ $AccFlags="XXXXXXXXXXXXXXXXXXX" ;}
    if($LMPASS=~ m/^$/){ $LMPASS="XXXXXXXXXXXXXXXXXXX" ;}
print <<eof
dn: uid=$uid,$userdn
homeDirectory: $home
ou: $ou
sn: $sn
description: $desc
sambaProfilePath: \\\\$servidor\\Profiles\\$uid
cn: $cn
uidNumber: $uidnumber
gidNumber: $gidnumber
sambaPwdCanChange: 2147483647
sambaHomePath: \\\\$servidor\\homes
uid: $uid
sambaLogoffTime: 2147483647
sambaLogonTime: 0
gecos: $gecos
sambaHomeDrive: H:
sambaSID: $SID-$ruid
sambaKickoffTime: 2147483647
sambaLogonScript: usuario.cmd
sambaPrimaryGroupSID: $SID-$rgid
loginShell: /bin/bash
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: sambaSamAccount
objectClass: qmailUser
objectClass: top
mail: $uid\@grupounitas.com
sambaLMPassword: $LMPASS
sambaAcctFlags: $AccFlags
sambaNTPassword: $NTPASS
sambaPwdLastSet: $PwdLastSet
sambaPwdMustChange: 2147483647
userPassword: {CRYPT}$userPassword

eof

}
foreach (@bypass){
    $hbypass{$_}=1;
}
foreach (@groupbypass){
    $gbypass{$_}=1;
}
while(<GROUP>){
    my($gid,$pass,$gidnumber,$userlist) = split /:/;
    next if exists($gbypass{$gid});
    my (@members) = split (/\,/,$userlist); 
    geragroup($gid,$gidnumber,\@members);
}

while(<SHADOW>){
    my($uid,@resto)=split /:/;
    $shadow{$uid}=\@resto;
}
while(<SMBPASSWD>){
    my($uid,@resto)=split /:/;
    $smbpasswd{$uid}=\@resto;
}
while(<PASSWD>){
    my($uid,$pass,@resto)= split /:/;
    $passwd{$uid}=\@resto;
    next if exists($hbypass{$uid});
    next if $uid =~ /\$$/;
    gerauser($uid);    
}
