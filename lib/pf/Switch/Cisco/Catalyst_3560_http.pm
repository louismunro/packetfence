package pf::Switch::Cisco::Catalyst_3560_http;

=head1 NAME

pf::Switch::Cisco::Catalyst_3560_http

=head1 DESCRIPTION

Object oriented module to access and configure Cisco Catalyst 3560 switches supporting webauth

This module is currently only a placeholder, see pf::Switch::Cisco::Catalyst_2960.

=head1 SUPPORT STATUS

=over

=item port-security

12.2(50)SE1 has been reported to work fine

12.2(25)SEC1 has issues

=item port-security + Voice over IP (VoIP)

Recommended IOS is 12.2(55)SE4.

=item MAC-Authentication / 802.1X

The hardware should support it.

802.1X support was never tested by Inverse.

=back

=head1 BUGS AND LIMITATIONS

Because a lot of code is shared with the 2950 make sure to check the BUGS AND LIMITATIONS section of 
L<pf::Switch::Cisco::Catalyst_2950> also.

=over 

=item port-security + Voice over IP (VoIP)

=over

=item IOS 12.2(25r) disappearing config

For some reason when securing a MAC address the switch loses an important portion of its config.
This is a Cisco bug, nothing much we can do. Don't use this IOS for VoIP.
See issue #1020 for details.

=item IOS 12.2(55)SE1 voice VLAN issues

For some reason this IOS doesn't put VoIP devices in the voice VLAN correctly.
This is a Cisco bug, nothing much we can do. Don't use this IOS for VoIP.
12.2(55)SE4 is working fine.

=back

=back

=cut

use strict;
use warnings;

use Log::Log4perl;
use Net::SNMP;

use pf::config;
use pf::node qw(node_attributes node_view);
use pf::Switch::constants;
use pf::util;
use pf::roles::custom;
use pf::accounting qw(node_accounting_current_sessionid);
use pf::util::radius qw(perform_coa perform_disconnect);
use pf::web::util;
use pf::violation qw(violation_count_trap);

use base ('pf::Switch::Cisco::Catalyst_2960_http');

sub description {'Cisco Catalyst 3560 with Web Auth'}

# CAPABILITIES
# inherited from 2960

sub setModeTrunk {
    my ( $this, $ifIndex, $enable ) = @_;
    my $logger                        = Log::Log4perl::get_logger( ref($this) );
    my $OID_vlanTrunkPortDynamicState = "1.3.6.1.4.1.9.9.46.1.6.1.1.13";           #CISCO-VTP-MIB
    my $OID_vlanTrunkEncapsulation    = "1.3.6.1.4.1.9.9.46.1.6.1.1.3";

    # $mode = 1 -> switchport mode trunk
    # $mode = 2 -> switchport mode access

    if ( !$this->isProductionMode() ) {
        $logger->info("not in production mode ... we won't change this port vlanTrunkPortDynamicState");
        return 1;
    }
    if ( !$this->connectWrite() ) {
        return 0;
    }

    my $truthValue = $enable ? $SNMP::TRUE         : $SNMP::FALSE;
    my $trunkMode  = $enable ? $CISCO::TRUNK_DOT1Q : $CISCO::TRUNK_AUTO;
    $logger->trace("SNMP set_request for vlanTrunkEncapsulation: $OID_vlanTrunkEncapsulation");
    my $result = $this->{_sessionWrite}->set_request(
        -varbindlist => [ "$OID_vlanTrunkEncapsulation.$ifIndex", Net::SNMP::INTEGER, $trunkMode ] );
    $logger->trace("SNMP set_request for vlanTrunkPortDynamicState: $OID_vlanTrunkPortDynamicState");
    $result = $this->{_sessionWrite}->set_request(
        -varbindlist => [ "$OID_vlanTrunkPortDynamicState.$ifIndex", Net::SNMP::INTEGER, $truthValue ] );

    return ( defined($result) );
}

sub returnRadiusAccessAccept {
    my ( $this, $vlan, $mac, $port, $connection_type, $user_name, $ssid, $wasInline, $user_role ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );

    my $node_info = node_view($mac);
    my $role;

    # default reply
    my $radius_reply_ref = {};

    if ( defined($user_role) && $user_role ne "" ) { $role = $this->getRoleByName($user_role); }

    # REGISTERED DEVICES
    if ( $node_info->{'status'} eq $pf::node::STATUS_REGISTERED ) {

        # RETURN AN ACL
        if ( isenabled( $this->{_AccessListMap} ) && $this->supportsAccessListBasedEnforcement ) {
            $logger->debug( "[$mac] ("
                    . $this->{'_id'}
                    . ") Network device supports ACLs. Evaluating ACLs to be returned" );
            if ( defined($user_role) && $user_role ne "" ) {
                my $access_list = $this->getAccessListByName($user_role);
                my @av_pairs;
                while ( $access_list =~ /([^\n]+)\n?/g ) {
                    push( @av_pairs, $this->returnAccessListAttribute . "=" . $1 );
                    $logger->info(
                        "[$mac] (" . $this->{'_id'} . ") Adding access list : $1 to the RADIUS reply" );
                }
                $radius_reply_ref->{'Cisco-AVPair'} = \@av_pairs;
                $logger->info( "[$mac] (" . $this->{'_id'} . ") Added access lists to the RADIUS reply." );
            }
        }
        # RETURN A ROLE
        elsif ( isenabled( $this->{_RoleMap} ) && $this->supportsRoleBasedEnforcement() ) {
            $logger->debug( "[$mac] ("
                    . $this->{'_id'}
                    . ") Network device supports roles. Evaluating role to be returned" );
            if ( defined($role) && $role ne "" ) {
                $radius_reply_ref->{ $this->returnRoleAttribute() } = $role;
                $logger->info( "[$mac] ("
                        . $this->{'_id'}
                        . ") Added role $role to the returned RADIUS Access-Accept under attribute "
                        . $this->returnRoleAttribute() );
            }
            else {
                $logger->warn( "[$mac] ("
                        . $this->{'_id'}
                        . ") Received undefined role. No Role added to RADIUS Access-Accept" );
            }
        }
        else {
            # RETURN A VLAN ID
            if ( ( !$wasInline || ( $wasInline && $vlan ne 0 ) ) && isenabled( $this->{_VlanMap} ) ) {
                $radius_reply_ref = {
                    'Tunnel-Private-Group-ID' => $vlan,
                    'Tunnel-Medium-Type'      => $RADIUS::ETHERNET,
                    'Tunnel-Type'             => $RADIUS::VLAN,
                };
            }
            else {
                $logger->warn(
                    "[$mac] (" . $this->{'_id'} . ") No Role or VLAN added to RADIUS Access-Accept" );
            }
        }
    }
    # UNREGISTERED DEVICES
    else {
        my (%session_id);
        pf::web::util::session( \%session_id, undef, 6 );

        my $acl
            = isenabled( $this->{_AccessListMap} ) && $this->supportsAccessListBasedEnforcement ? 
                $this->getAccessListByName($user_role)
            : isenabled( $this->{_RoleMap} ) && $this->supportsRoleBasedEnforcement() ? 
                $this->getRoleByName($user_role)
            : $vlan;
            #my $acl = $this->getAccessListByName($user_role) // $this->getRoleByName($user_role) // $vlan;
        $session_id{client_mac} = $mac;
        $session_id{wlan}       = $ssid;
        $session_id{switch_id}  = $this->{_id};
        $radius_reply_ref       = {
            'User-Name'    => $mac,
            'Cisco-AVPair' => [
                "url-redirect-acl=$acl",
                "url-redirect=" . $this->{'_portalURL'} . "/cep$session_id{_session_id}"
            ],
        };
        $logger->info( "[$mac] (" . $this->{'_id'} . ") Adding access list : $acl to the RADIUS reply" );

    }

    return [ $RADIUS::RLM_MODULE_OK, %$radius_reply_ref ];
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2013 Inverse inc.

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
