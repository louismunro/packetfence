#!/usr/bin/perl 
# overwrite a list of variables in conf/networks.conf based on local config
use warnings;
use strict;

use Config::IniFiles;
my $pf_networks_file = "/usr/local/pf/conf/networks.conf";
my @local_vars       = qw(
  dns
  dhcpd
);

my $master = Config::IniFiles->new( -file => "$pf_networks_file.master" );
my @networks = $master->Sections;

for my $network (@networks) {
    $master->delval( $network, $_ ) for @local_vars;
}

my $new_whole = Config::IniFiles->new(
    -file   => "$pf_networks_file.local",
    -import => $master
);

$new_whole->WriteConfig("$pf_networks_file");
