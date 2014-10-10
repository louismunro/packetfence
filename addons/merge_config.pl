#!/usr/bin/perl
# Write a specific list of configuration sections taken from pf.conf to conf/local/global

use Config::IniFiles;
my $pf_config_file = "/usr/local/pf/conf/pf.conf";
my @local_sections = ('services', 'interface eth0', 'interface eth1');

my $master = Config::IniFiles->new( -file => "$pf_config_file.master"  );

$master->DeleteSection($_) for @local_sections;

my $new_whole =  Config::IniFiles->new(  -file => "$pf_config_file.local", -import => $master);

$new_whole->WriteConfig("$pf_config_file");
