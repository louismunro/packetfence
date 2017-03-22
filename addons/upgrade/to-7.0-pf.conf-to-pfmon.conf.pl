#!/usr/bin/perl

=head1 NAME

addons/migrate-config-to-pfmon-conf.pl

=cut

=head1 DESCRIPTION

A script to migrate the configuration of maintenance.* to pfmon.conf

=cut

use strict;
use warnings;
use lib qw(/usr/local/pf/lib);
use pf::IniFiles;
use pf::file_paths qw($pfmon_config_file $pf_config_file);
use Data::Dumper;
use pf::ConfigStore::Pfmon;

my $ini = pf::IniFiles->new(-file => $pf_config_file);

if (!$ini->SectionExists('maintenance')) {
    print "Nothing to migrate\n";
    exit 0;
}

my $cs = pf::ConfigStore::Pfmon->new;

my $items = $cs->readAll('id');

foreach my $item (@$items) {
    my $id = delete $item->{id};
    my %values;
    if ($ini->exists("maintenance", $id)) {
        my $old_value = $ini->val("maintenance", $id);
        $ini->delval("maintenance", $id);
        $values{enabled} = $old_value;
    }
    while (my ($key, $value) = each %$item) {
        my $old_key_name = "${id}_$key";
        if (!$ini->exists("maintenance", $old_key_name)) {
            next;
        }
        my $old_value = $ini->val("maintenance", $old_key_name);
        print "Migrating maintenance.$old_key_name $old_value to conf/pfmon.conf\n";
        $values{$key} = $old_value;
        $ini->delval("maintenance", $old_key_name);
    }
    $cs->update($id, \%values);
}

$ini->DeleteSection("maintenance");

$cs->commit;
$ini->RewriteConfig;

print "Finish migrating config to conf/pfmon.conf\n";

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2017 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

