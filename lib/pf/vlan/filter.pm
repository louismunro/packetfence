package pf::vlan::filter;

=head1 NAME

pf::vlan::filter - handle the authorization rules on the vlan attribution

=cut

=head1 DESCRIPTION

pf::vlan::filter deny, rewrite role based on rules. 

=cut

use strict;
use warnings;

use Log::Log4perl;
use Time::Period;
use pf::config qw(%connection_type_to_str);
use pf::person qw(person_view);
our ( %ConfigVlanFilters, $cached_vlan_filters_config );

readVlanFiltersFile();

=head1 SUBROUTINES

=over

=item new

=cut

sub new {
    my $logger = Log::Log4perl::get_logger("pf::vlan::filter");
    $logger->debug("instantiating new pf::vlan::filter");
    my ( $class, %argv ) = @_;
    my $self = bless {}, $class;
    return $self;
}

=item test

Test all the rules

=cut

sub test {
    my ($self,      $scope,           $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );

    foreach my $rule ( sort keys %ConfigVlanFilters ) {

        if ( defined( $ConfigVlanFilters{$rule}->{'scope'} )
            && $ConfigVlanFilters{$rule}->{'scope'} eq $scope )
        {
            my ( $index, $test ) = split( ':', $rule );
            if ( defined $test ) {

                my $boolean = $self->dispatch_rule(
                    $ConfigVlanFilters{$test},
                    $switch, $ifIndex, $mac, $node_info, $connection_type_to_str{$connection_type},
                    $user_name, $ssid, $radius_request, $test
                );

                if ( eval $boolean ) {
                    $logger->info( "Match Vlan rule: " . $rule . " for " . $mac );
                    my $role = $ConfigVlanFilters{$rule}->{'role'};

                    #TODO Add action that can be sent to the WebAPI
                    my $vlan = $switch->getVlanByName($role);
                    return ( $vlan, $role );
                }
            }
        }
    }
}

=item dispatch_rules

Return a boolean expression encoding the rule to evaluate.
E.g. "1||0" or "1&&1||0".

=cut

our $disp_table = {
    node_info       => \&node_info_parser,
    switch          => \&switch_parser,
    ifIndex         => \&ifindex_parser,
    mac             => \&mac_parser,
    connection_type => \&connection_type_parser,
    username        => \&username_parser,
    ssid            => \&ssid_parser,
    time            => \&time_parser,
    owner           => \&owner_parser,
    radius_request  => \&radius_parser,
};

sub dispatch_rule {
    my ( $self, $rule, $switch, $ifIndex, $mac, $node_info, $connection_type, $user_name, $ssid,
        $radius_request, $name )
        = @_;
    my $logger = Log::Log4perl::get_logger( ref($self) );

    if ( @_ < 11 ) {
        $logger->error("Missing arguments to dispatch rule $rule");
        return 0;
    }


    my $bool = $disp_table->{ $rule->{'filter'} }->(@_);
    $bool =~ s/\d([|&])\d/$1$1/g;    # replace | and & with || and &&
    return $bool;
}

=item generic_matcher

Parse the operator and compare the operands to the rule. If it matches then return 1.

=cut

sub generic_matcher {
    my ( $self, $rule, $operand ) = @_;

    # evaluate the operator and return either 1 or 0 ( NOT true or false )
    use Switch; #  perl switch, not pf::switch. 
    switch ( $rule->{'operator'} ) {
        case 'is'        { $operand eq $rule->{'value'}    ? 1 : 0 }
        case 'is_not'    { $operand ne $rule->{'value'}    ? 1 : 0 }
        case 'match'     { $operand =~ m/$rule->{'value'}/ ? 1 : 0 }
        case 'match_not' { $operand !~ m/$rule->{'value'}/ ? 1 : 0 }
        else             { return 0 }
    }
}

=item node_info_parser

Parse the node_info attribute and compare to the rule. If it matches then perform the action.

=cut

sub node_info_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined($node_info) ) {
        return $self->generic_matcher( $rule, $node_info->{ $rule->{'attribute'} } );
    }
    else {
        return 0;
    }
}

=item radius_parser

Parse the RADIUS request attribute and compare to the rule. If it matches then perform the action.

=cut

sub radius_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined($radius_request) ) {
        return $self->generic_matcher( $rule, $radius_request->{ $rule->{'attribute'} } );
    }
    else {
        return 0;
    }
}

=item owner_parser

Parse the owner attribute and compare to the rule. If it matches then perform the action.

=cut

sub owner_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    my $owner = person_view( $node_info->{'pid'} );

    if ( defined($owner) ) {
        return $self->generic_matcher( $rule, $owner->{ $rule->{'attribute'} } );
    }
    else {
        return 0;
    }
}

=item switch_parser

Parse the switch attribute and compare to the rule. If it matches then return true.

=cut

sub switch_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined($switch) ) {
        return $self->generic_matcher( $rule, $switch->{ $rule->{'attribute'} } );
    }
    else {
        return 0;
    }
}

=item ifindex_parser

Parse the ifindex value and compare to the rule. If it matches then return true.

=cut

sub ifindex_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined $ifIndex ) {
        return $self->generic_matcher( $rule, $ifIndex );
    }
    else {
        return 0;
    }
}

=item mac_parser

Parse the mac value and compare to the rule. If it matches then return.

=cut

sub mac_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined($mac) ) {
        return $self->generic_matcher( $rule, $mac );
    }
    else {
        return 0;
    }
}

=item connection_type_parser

Parse the connection_type value and compare to the rule. If it matches then return true.

=cut

sub connection_type_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined($connection_type) ) {
        return $self->generic_matcher( $rule, $connection_type_to_str{$connection_type} );
    }
    else {
        return 0;
    }
}

=item username_parser

Parse the username value and compare to the rule. If it matches then return true.

=cut

sub username_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined $user_name ) {
        return $self->generic_matcher( $rule, $user_name );
    }
    else {
        return 0;
    }
}

=item ssid_parser

Parse the ssid valus and compare to the rule. If it matches then return true.

=cut

sub ssid_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    if ( defined($ssid) ) {
        return $self->generic_matcher( $rule, $ssid );
    }
    else {
        return 0;
    }
}

=item time_parser

Check the current time and compare to the period

=cut

sub time_parser {
    my ($self,      $rule,            $switch,    $ifIndex, $mac,
        $node_info, $connection_type, $user_name, $ssid,    $radius_request
    ) = @_;

    my $time = time();
    if ( $rule->{'operator'} eq 'is' ) {
        if ( inPeriod( $time, $rule->{'value'} ) ) {
            return 1;
        }
        else {
            return 0;
        }
    }
    elsif ( $rule->{'operator'} eq 'is_not' ) {
        if ( !inPeriod( $time, $rule->{'value'} ) ) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        return 0;
    }
}

=item readVlanFiltersFile - vlan_filters.conf

=cut

sub readVlanFiltersFile {
    $cached_vlan_filters_config = pf::config::cached->new(
        -file       => $vlan_filters_config_file,
        -allowempty => 1,
        -onreload   => [
            reload_vlan_filters_config => sub {
                my ($config) = @_;
                $config->toHash( \%ConfigVlanFilters );
                $config->cleanupWhitespace( \%ConfigVlanFilters );
                }
        ]
    );
    if (@Config::IniFiles::errors) {
        my $logger = Log::Log4perl::get_logger("pf::vlan::filter");
        $logger->logcroak( join( "\n", @Config::IniFiles::errors ) );
    }
}

=back

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

Minor parts of this file may have been contributed. See CREDITS.

=head1 COPYRIGHT

Copyright (C) 2005-2014 Inverse inc.

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

1;

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
