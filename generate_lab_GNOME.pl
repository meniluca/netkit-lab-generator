#!/usr/bin/perl

# Author: Luca Menichetti
#
# Da un file semplice chiamato "pcs.list"
# genera tutto il necessario alla creazione di un lab
# per netkit.


# Librerie
use 5.006;
use strict;
use Switch;

# Metodo "uniq" che da una lista di elementi
# ritorna la lista degli elementi senza doppioni
sub uniq {

    my @list = @_;

    my @uniq_list;
    
    my $new_elem = pop(@list);
    push(@uniq_list, $new_elem);
    
    foreach (0 .. $#list){

        foreach my $elem (@list){

            if ($elem eq $new_elem) {
                pop(@uniq_list);
                last;
            }

        }
        $new_elem = pop(@list);
        push(@uniq_list, $new_elem);
    
    }

    my @uniq_list_reversed = reverse(@uniq_list);

    return @uniq_list_reversed;

}

# Metodo "calc_netmask" che dalla stringa "prefisso/netmask", dove la netmask e' specificata
# nella notazione CIDR, ritorna la coppia (prefisso, netmask) dove netmask e' nella notazione esplicita
sub calc_netmask {
    
    my ($prefix,$netmask) = split( /\// ,$_[0]);

    switch ($netmask) {
        case "1"    { $netmask = "128.0.0.0"; }
        case "2"    { $netmask = "192.0.0.0"; }
        case "3"    { $netmask = "224.0.0.0"; }
        case "4"    { $netmask = "240.0.0.0"; }
        case "5"    { $netmask = "248.0.0.0"; }
        case "6"    { $netmask = "252.0.0.0"; }
        case "7"    { $netmask = "254.0.0.0"; }
        case "8"    { $netmask = "255.0.0.0"; }
        case "9"    { $netmask = "255.128.0.0"; }
        case "10"   { $netmask = "255.192.0.0"; }
        case "11"   { $netmask = "255.224.0.0"; }
        case "12"   { $netmask = "255.240.0.0"; }
        case "13"   { $netmask = "255.248.0.0"; }
        case "14"   { $netmask = "255.252.0.0"; }
        case "15"   { $netmask = "255.254.0.0"; }
        case "16"   { $netmask = "255.255.0.0"; }
        case "17"   { $netmask = "255.255.128.0"; }
        case "18"   { $netmask = "255.255.192.0"; }
        case "19"   { $netmask = "255.255.224.0"; }
        case "20"   { $netmask = "255.255.240.0"; }
        case "21"   { $netmask = "255.255.248.0"; }
        case "22"   { $netmask = "255.255.252.0"; }
        case "23"   { $netmask = "255.255.254.0"; }
        case "24"   { $netmask = "255.255.255.0"; }
        case "25"   { $netmask = "255.255.255.128"; }
        case "26"   { $netmask = "255.255.255.192"; }
        case "27"   { $netmask = "255.255.255.224"; }
        case "28"   { $netmask = "255.255.255.240"; }
        case "29"   { $netmask = "255.255.255.248"; }
        case "30"   { $netmask = "255.255.255.252"; }
        case "31"   { $netmask = "255.255.255.254"; }
        else        { $netmask = "255.255.255.255"; }
    }
    
    return ($prefix,$netmask);
}

# Controllo se esiste il file "pcs.list"
unless (-e "pcs.list") {
    print "ERRORE: il file pcs.list non esiste!\n";
    exit 1;
}

# Leggo il file "pcs.list"
open(PCLIST, 'pcs.list');
my @lines = <PCLIST>;
close(PCLIST);

# Per ogni linea del file, se corrisponde a una dichiarazione
# di un computer chiamato "xxxx", creo il file "xxxx.startup"
# e la relativa cartella "xxxx". Nessun problema se incontro piu'
# volte la dichiarazione dello stesso computer.
my $line;
foreach $line (@lines)
{
    # Se la linea corrente è una dichiarazione di una lan
    # o una linea vuota, passo oltre
    if ( $line =~ /(^#|^\s*$)/ )
    {
        next;
    }
    
    # Parso la linea della dichiarazione prendendo il nome,
    # che è il primo elemento.
    my @separated_line = split(/,/, $line);
    my @name_ip_and_device = split( /\s+/ ,$separated_line[0]);

    my $name = $name_ip_and_device[0];

    system "mkdir -p $name";
    system "touch $name.startup"
    
}

# Creo il file lab.conf
system "touch lab.conf";
system "echo \"\" > lab.conf";
open(LABCONF, '>>lab.conf');
print LABCONF "# Generated automatically\n";
print LABCONF "\n";
print LABCONF "LAB_DESCRIPTION=\"Lab creato automaticamente.\"\n" ;
print LABCONF "LAB_VERSION=1.0\n" ;
print LABCONF "LAB_AUTHOR=\"$ENV{'USER'}\"\n" ;
print LABCONF "LAB_EMAIL=\n" ;
print LABCONF "LAB_WEB=http://www.netkit.org/\n" ;
close(LABCONF);

# Dichiaro le variabili predefinite
my $prefix = "0.0.0.0";
my $netmask = "255.255.255.255";
my $device = "eth0";
my $lan = "X";

# Dichiaro le liste dei servizi che conterranno
# l'elenco di chi eroghera' quel servizio
my @list_dns;
my @list_ws;
my @list_zebra;
my @list_rip;
my @list_ospf;
my @list_bgp;

# Rileggo il file "pc.list"
foreach $line (@lines)
{
    # Se la linea è vuota
    if ( $line =~ /^\s*$/ )
    {
        next;
    }
    
    # Se la linea è un descrittore della lan
    if ( $line =~ /^#/ )
    {
        
        # calcolo l'identificatore della lan, il prefisso e la netmask.
        # NOMELAN PREFISSO/NETMASK --> # A 10.0.0.0/24
        # oppure
        # NOMELAN PREFISSO NETMASK --> # A 10.0.0.0 255.255.255.0
        
        # Parso la stringa creando un array con tutti gli elementi che descrivono la lan
        my @lan_descriptions = split(/\s+/, $line);
        
        # Conto quanti elementi ci sono
        my $count_elem = split(/\s+/, $line);
        
        # Se c'e' solo un elemento
        if ( $count_elem == 1 ){
            # C'è solo il cancelletto per cui il resto lo aggiungo io
            $prefix = "0.0.0.0";
            $netmask = "255.255.255.255";
            $lan = "X";
            `echo "" >> lab.conf`;
            print "Attenzione: non è stato specificato nessun dettaglio nella definizione di una lan (default: prefisso = $prefix , netmask = $netmask , lan = $lan)\n";
            next;
        }
        
        # Essendoci più di un elemento dopo il cancelletto, il successivo è il nome della lan
        # $lan_descrioptions[0] è il cancelletto        
        $lan = $lan_descriptions[1];

        # Se ci sono 2 elementi
        if ( $count_elem == 2 ){
            # C'è solo il nome della lan per cui il resto lo aggiungo io
            $prefix = "0.0.0.0";
            $netmask = "255.255.255.255";
            `echo "" >> lab.conf`;
            print "Attenzione: non è stato specificato nessun dettaglio nella definizione della lan \"$lan\" (default: prefisso = $prefix , netmask = $netmask)\n";
            next;
        }

        # Se ci sono più di 2 elementi devo calcolare prefisso e netmarsk

        # Se gli elementi sono 4 avremo 192.168.2.0 255.255.255.0
        if ( $count_elem == 4 ){
            $prefix = $lan_descriptions[2];
            $netmask = $lan_descriptions[3];
            next;
        }

        # Se più di 4... c'è un errore.
        if ( $count_elem >= 5 ){
            $prefix = $lan_descriptions[2];
            $netmask = $lan_descriptions[3];
            print "Attenzione: ci sono più elementi di quelli richiesti nella definizione della lan \"$lan\" (calcolati: prefisso = $prefix , netmask = $netmask)\n";
            next;
        }

        # Gli elementi sono 3
        ($prefix,$netmask) = calc_netmask($lan_descriptions[2]);
        
        # Dei controlli per sicurezza
        if (!$prefix){
            $prefix = "0.0.0.0";
        }
        if (!$netmask){
            $netmask = "255.255.255.255";
        }

        # TODO inserire controllo ip valido, netmask e nomelan valide
        `echo "" >> lab.conf`;
        
        next;
        
    }
    
    # Se la linea corrente del file non è vuota e non è la definizione di una lan
    # è la definizione di una macchina

    # La definizione è la seguente: "nomemacchina .ultimo_byte_ip interfaccia, listaservizi"
    # Parso la prima parte della linea con i dati della macchina (prima della virgola) e la seconda con i servizi
    my @separated_line = split(/,/, $line);
    my @name_ip_and_device = split( /\s+/ ,$separated_line[0]);
    
    my @services;
    if ($separated_line[1])
    {
        @services = split( /\s+/ ,$separated_line[1]);
    }
    
    # Se prima della virgola ci sono 4 elementi è stato definito male qualche cosa
    if ($name_ip_and_device[3]) {
        print "ERRORE: non è stata ben formata la definizione di una macchina nella linea \"$line\"\n";
        exit 1;
    }

    # Parso il nome della macchina...
    my $name = $name_ip_and_device[0];
    
    # ... e il suo ip. $ip in realtà è solo l'ultimo byte dell'ip
    my $ip = $name_ip_and_device[1];

    # Se non e' un numero...
    $_ = $ip;
    if ( ! /^\.[0-9]+$/) {
        if ( /^[0123456789]+$/ ){
            # ...o l'utente non ha inserito il punto "." prima del numero...
            print "Attenzione: rispettare la sintassi. L\'ultimo byte della macchina $name sulla lan $prefix sara\' $ip (sintassi \".xxx\")\n";
            $ip = ".$ip"
        } else {
            # ...oppure non e' stato specificato nessun indirizzo
            print "Attenzione: non è stato specificato l'ultimo byte per l'indirizzo ip di $name sulla lan $prefix (default: .1)\n";            
            $ip = ".1";
        }
    }
    
    # Parso l'interfaccia di rete
    my $device = $name_ip_and_device[2];
    
    # Se non c'e'...
    if (! $device ){
        # ...forse sta in $name_ip_and_device[1] perchè l'utente non ha messo l'ip
        $device = $name_ip_and_device[1];
    }

    # Se non e' un nome valido "eth0" "eth13"...
    $_ = $device;
    if ( ! /^[a-zA-Z]+[0-9]+$/ ){
        # ... l'utente non ha specificato un interfaccia
        print "Attenzione: non è stata specificata un'interfaccia per $name sulla lan $prefix (default: eth0)\n";
        $device = "eth0";
    }

    # Calcolo l'indirizzo ip unendo il prefisso con l'ultimo byte dell'ip
    my $calculated_ip = $prefix;
    if ($ip){
        my @ipv4 = split(/\./,$prefix);
        $" = ".";
        $ipv4[3] = substr($ip,1); 
        $calculated_ip = "@ipv4";
        $" = " ";
    }
    
    # Costruisco la stringa da inserire nel file $name.startup
    my $ifconfig_string = "ifconfig $device $calculated_ip netmask $netmask up";
    
    # Un messaggio con finestra di dialogo che chiede di confermare eventualmente dopo aver manipolato
    # la stringa $ifconfig_string
    my $string_startup = `zenity --entry --text="$name" --entry-text="$ifconfig_string" --width=600`;
    
    # Scrivo la stringa nel file
    `echo -n "$string_startup" >> $name.startup`;
    
    # Aggiungo la definizione di macchina che afferisce alla lan nel file lab.conf
    my @ethX = split(/^[A-z]+/,$device);
    my $ethX = $ethX[1];
    `echo $name\[$ethX\]=$lan >> lab.conf`;
    
    # STAMPE A VIDEO

    print "---------------------\n";
    print "NOME: $name\n";
    print "DEVICE: $device\n";
    print "$name.startup : $string_startup";

    # Se ci sono servizi per la macchina li notifico a video
    # e aggiungo la macchina alla lista dei relativi servizi
    if ( @services )
    {
        print "Offre questi servizi: @services\n";
        my $service;
        foreach $service (@services){
            if ($service =~ /nameserver/){
                push(@list_dns,$name);
            }
            if ($service =~ /webserver/){
                push(@list_ws,$name);
            }
            if ($service =~ /zebra/){
                push(@list_zebra,$name);
            }
            if ($service =~ /rip/){
                push(@list_rip,$name);
            }
            if ($service =~ /ospf/){
                push(@list_ospf,$name);
            }
            if ($service =~ /bgp/){
                push(@list_bgp,$name);
            }
        }
    }
    print "---------------------\n";
    
}

# AGGIUNTA DEI SERVIZI ALLE MACCHINE

# Definisco la lista delle macchine per ogni servizio
my @unique_dns = uniq(@list_dns);
my @unique_ws = uniq(@list_ws);
my @unique_zebra = uniq(@list_zebra);
my @unique_rip = uniq(@list_rip);
my @unique_ospf = uniq(@list_ospf);
my @unique_bgp = uniq(@list_bgp);

foreach my $name ( @unique_dns ) {
    if ($name eq "") {
        next;
    }
    `echo "/etc/init.d/bind start" >> $name.startup`;
    `mkdir -p $name/etc/bind`;
    `touch $name/etc/bind/db.root`;
    `touch $name/etc/bind/named.conf`;
}


foreach my $name ( @unique_ws ) {
    if ($name eq "") {
        next;
    }
    `echo "/etc/init.d/apache2 start" >> $name.startup`;
    `mkdir -p $name/var/www`;
    `touch $name/var/www/index.html`;
    `echo "<html>" > $name/var/www/index.html`;
    `echo "<head>" >> $name/var/www/index.html`;
    `echo "<title>$name</title>" >> $name/var/www/index.html`;
    `echo "</head>" >> $name/var/www/index.html`;
    `echo "<body>" >> $name/var/www/index.html`;
    `echo "<h1>$name</h1>" >> $name/var/www/index.html`;
    `echo "</body>" >> $name/var/www/index.html`;
    `echo "</html>" >> $name/var/www/index.html`;
}


foreach my $name ( @unique_zebra ) {
    if ($name eq "") {
        next;
    }       
    `echo "/etc/init.d/zebra start" >> $name.startup`;
    `mkdir -p $name/etc/zebra`;
    `touch $name/etc/zebra/zebra.conf`;
    `touch $name/etc/zebra/daemons`;
    
    `echo "hostname zebra" >> $name/etc/zebra/zebra.conf`;
    `echo "password zebra" >> $name/etc/zebra/zebra.conf`;
    `echo "enable password zebra" >> $name/etc/zebra/zebra.conf`;
    
    `echo "# This file tells the zebra package" >> $name/etc/zebra/daemons`;
    `echo "# which daemons to start." >> $name/etc/zebra/daemons`;
    `echo "# Entries are in the format: <daemon>=(yes|no|priority)" >> $name/etc/zebra/daemons`;
    `echo "# where 'yes' is equivalent to infinitely low priority, and" >> $name/etc/zebra/daemons`;
    `echo "# lower numbers mean higher priority. Read" >> $name/etc/zebra/daemons`;
    `echo "# /usr/doc/zebra/README.Debian for details." >> $name/etc/zebra/daemons`;
    `echo "# Daemons are: bgpd zebra ospfd ospf6d ripd ripngd" >> $name/etc/zebra/daemons`;
    `echo "zebra=yes" >> $name/etc/zebra/daemons`;
    `echo "bgpd=no" >> $name/etc/zebra/daemons`;
    `echo "ospfd=no" >> $name/etc/zebra/daemons`;
    `echo "ospf6d=no" >> $name/etc/zebra/daemons`;
    `echo "ripd=no" >> $name/etc/zebra/daemons`;
    `echo "ripngd=no" >> $name/etc/zebra/daemons`;
    `echo "" >> $name/etc/zebra/daemons`;
}

foreach my $name ( @unique_rip ) {
    if ($name eq "") {
        next;
    }
    `touch $name/etc/zebra/ripd.conf`;
    `echo "!" >> $name/etc/zebra/ripd.conf`;
    `echo "hostname ripd" >> $name/etc/zebra/ripd.conf`;
    `echo "password zebra" >> $name/etc/zebra/ripd.conf`;
    `echo "enable password zebra" >> $name/etc/zebra/ripd.conf`;
    `echo "!" >> $name/etc/zebra/ripd.conf`;
    `echo "router rip" >> $name/etc/zebra/ripd.conf`;
    `echo "redistribute connected" >> $name/etc/zebra/ripd.conf`;
    `echo "network XXX.XXX.XXX.XXX/NM" >> $name/etc/zebra/ripd.conf`;
    `echo "!" >> $name/etc/zebra/ripd.conf`;
    `echo "log file /var/log/zebra/ripd.log" >> $name/etc/zebra/ripd.conf`;
    `echo "" >> $name/etc/zebra/ripd.conf`;

    my $daemons_file = "$name/etc/zebra/daemons";

    open(READFILE, "<$daemons_file");
    my @lines = <READFILE>;
    close READFILE;
    
    open(WRITEFILE,">$daemons_file");
    
    foreach(@lines) {
        s/ripd=no/ripd=yes/;
        print WRITEFILE;
    }

    close WRITEFILE;
    # TODO cambiare in yes daemons
}


foreach my $name ( @unique_ospf ) {
    if ($name eq "") {
        next;
    }
    `touch $name/etc/zebra/ospfd.conf`;
    `echo "!" >> $name/etc/zebra/ospfd.conf`;
    `echo "hostname ospfd" >> $name/etc/zebra/ospfd.conf`;
    `echo "password zebra" >> $name/etc/zebra/ospfd.conf`;
    `echo "enable password zebra" >> $name/etc/zebra/ospfd.conf`;
    `echo "!" >> $name/etc/zebra/ospfd.conf`;
    `echo "interface eth0" >> $name/etc/zebra/ospfd.conf`;
    `echo "ospf cost 2" >> $name/etc/zebra/ospfd.conf`;
    `echo "router ospf" >> $name/etc/zebra/ospfd.conf`;
    `echo "!" >> $name/etc/zebra/ospfd.conf`;
    `echo "! Speak OSPF on all interfaces falling in the listed subnets" >> $name/etc/zebra/ospfd.conf`;
    `echo "network 223.0.2.0/30 area 1.1.1.1" >> $name/etc/zebra/ospfd.conf`;
    `echo "area 1.1.1.1 stub" >> $name/etc/zebra/ospfd.conf`;
    `echo "redistribute connected" >> $name/etc/zebra/ospfd.conf`;
    `echo "!" >> $name/etc/zebra/ospfd.conf`;
    `echo "log file /var/log/zebra/ospfd.log" >> $name/etc/zebra/ospfd.conf`;

    my $daemons_file = "$name/etc/zebra/daemons";

    open(READFILE, "<$daemons_file");
    my @lines = <READFILE>;
    close READFILE;
    
    open(WRITEFILE,">$daemons_file");
    
    foreach(@lines) {
        s/ospfd=no/ospfd=yes/;
        print WRITEFILE;
    }

    close WRITEFILE;
    # TODO cambiare in yes daemons
}

foreach my $name ( @unique_bgp ) {
    if ($name eq "") {
        next;
    }
    `touch $name/etc/zebra/bgpd.conf`;

    my $daemons_file = "$name/etc/zebra/daemons";

    open(READFILE, "<$daemons_file");
    my @lines = <READFILE>;
    close READFILE;
    
    open(WRITEFILE,">$daemons_file");
    
    foreach(@lines) {
        s/bgpd=no/bgpd=yes/;
        print WRITEFILE;
    }

    close WRITEFILE;

}
exit 0;

