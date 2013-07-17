package pf::SNMP::HP::Cluster_MSM710;

=head1 NAME

pf::SNMP::HP::Cluster_MSM710

=head1 SYNOPSIS

The pf::SNMP::HP::Cluster_MSM710 module manages access to HP Procurve Controller MSM710 clusters.
This module is necessary because deauthentication is different on standalone controllers versus clusters.

=head1 STATUS

Should work on all HP Wireless E series

Developed and tested on HP MSM 710 running firmware version 6.0.0.1-13249

=head1 BUGS AND LIMITATIONS

See pf::SNMP::HP::Controller_MSM710 for limitations.

=cut

use strict;
use warnings;

use Log::Log4perl;
use POSIX;

use base ('pf::SNMP::HP::Controller_MSM710');

use pf::config;
sub description { 'HP ProCurve MSM710 Mobility Cluster' }

=head1 SUBROUTINES

=over

=cut

sub new {
    my ( $class, %argv ) = @_;
    my $this = bless {
        '_error'                    => undef,
        '_ip'                       => undef,
        '_macSearchesMaxNb'         => undef,
        '_macSearchesSleepInterval' => undef,
        '_mode'                     => undef,
        '_sessionRead'              => undef,
        '_sessionWrite'             => undef,
        '_sessionControllerWrite'   => undef,
        '_SNMPAuthPasswordRead'     => undef,
        '_SNMPAuthPasswordTrap'     => undef,
        '_SNMPAuthPasswordWrite'    => undef,
        '_SNMPAuthProtocolRead'     => undef,
        '_SNMPAuthProtocolTrap'     => undef,
        '_SNMPAuthProtocolWrite'    => undef,
        '_SNMPCommunityRead'        => undef,
        '_SNMPCommunityTrap'        => undef,
        '_SNMPCommunityWrite'       => undef,
        '_SNMPEngineID'             => undef,
        '_SNMPPrivPasswordRead'     => undef,
        '_SNMPPrivPasswordTrap'     => undef,
        '_SNMPPrivPasswordWrite'    => undef,
        '_SNMPPrivProtocolRead'     => undef,
        '_SNMPPrivProtocolTrap'     => undef,
        '_SNMPPrivProtocolWrite'    => undef,
        '_SNMPUserNameRead'         => undef,
        '_SNMPUserNameTrap'         => undef,
        '_SNMPUserNameWrite'        => undef,
        '_SNMPVersion'              => 1,
        '_SNMPVersionTrap'          => 1,
        '_cliEnablePwd'             => undef,
        '_cliPwd'                   => undef,
        '_cliUser'                  => undef,
        '_cliTransport'             => undef,
        '_wsPwd'                    => undef,
        '_wsUser'                   => undef,
        '_wsTransport'              => undef,
        '_radiusSecret'             => undef,
        '_controllerIp'             => undef,
        '_uplink'                   => undef,
        '_vlans'                    => undef,
        '_VoIPEnabled'              => undef,
        '_roles'                    => undef,
        '_inlineTrigger'            => undef,
        '_deauthMethod'             => undef,
    }, $class;

    foreach ( keys %argv ) {
        if (/^-?SNMPCommunityRead$/i) {
            $this->{_SNMPCommunityRead} = $argv{$_};
        } elsif (/^-?SNMPCommunityTrap$/i) {
            $this->{_SNMPCommunityTrap} = $argv{$_};
        } elsif (/^-?SNMPCommunityWrite$/i) {
            $this->{_SNMPCommunityWrite} = $argv{$_};
        } elsif (/^-?ip$/i) {
            $this->{_ip} = $argv{$_};
        } elsif (/^-?macSearchesMaxNb$/i) {
            $this->{_macSearchesMaxNb} = $argv{$_};
        } elsif (/^-?macSearchesSleepInterval$/i) {
            $this->{_macSearchesSleepInterval} = $argv{$_};
        } elsif (/^-?mode$/i) {
            $this->{_mode} = $argv{$_};
        } elsif (/^-?SNMPAuthPasswordRead$/i) {
            $this->{_SNMPAuthPasswordRead} = $argv{$_};
        } elsif (/^-?SNMPAuthPasswordTrap$/i) {
            $this->{_SNMPAuthPasswordTrap} = $argv{$_};
        } elsif (/^-?SNMPAuthPasswordWrite$/i) {
            $this->{_SNMPAuthPasswordWrite} = $argv{$_};
        } elsif (/^-?SNMPAuthProtocolRead$/i) {
            $this->{_SNMPAuthProtocolRead} = $argv{$_};
        } elsif (/^-?SNMPAuthProtocolTrap$/i) {
            $this->{_SNMPAuthProtocolTrap} = $argv{$_};
        } elsif (/^-?SNMPAuthProtocolWrite$/i) {
            $this->{_SNMPAuthProtocolWrite} = $argv{$_};
        } elsif (/^-?SNMPPrivPasswordRead$/i) {
            $this->{_SNMPPrivPasswordRead} = $argv{$_};
        } elsif (/^-?SNMPPrivPasswordTrap$/i) {
            $this->{_SNMPPrivPasswordTrap} = $argv{$_};
        } elsif (/^-?SNMPPrivPasswordWrite$/i) {
            $this->{_SNMPPrivPasswordWrite} = $argv{$_};
        } elsif (/^-?SNMPPrivProtocolRead$/i) {
            $this->{_SNMPPrivProtocolRead} = $argv{$_};
        } elsif (/^-?SNMPPrivProtocolTrap$/i) {
            $this->{_SNMPPrivProtocolTrap} = $argv{$_};
        } elsif (/^-?SNMPPrivProtocolWrite$/i) {
            $this->{_SNMPPrivProtocolWrite} = $argv{$_};
        } elsif (/^-?SNMPUserNameRead$/i) {
            $this->{_SNMPUserNameRead} = $argv{$_};
        } elsif (/^-?SNMPUserNameTrap$/i) {
            $this->{_SNMPUserNameTrap} = $argv{$_};
        } elsif (/^-?SNMPUserNameWrite$/i) {
            $this->{_SNMPUserNameWrite} = $argv{$_};
        } elsif (/^-?cliEnablePwd$/i) {
            $this->{_cliEnablePwd} = $argv{$_};
        } elsif (/^-?cliPwd$/i) {
            $this->{_cliPwd} = $argv{$_};
        } elsif (/^-?cliUser$/i) {
            $this->{_cliUser} = $argv{$_};
        } elsif (/^-?cliTransport$/i) {
            $this->{_cliTransport} = $argv{$_};
        } elsif (/^-?wsPwd$/i) {
            $this->{_wsPwd} = $argv{$_};
        } elsif (/^-?wsUser$/i) {
            $this->{_wsUser} = $argv{$_};
        } elsif (/^-?wsTransport$/i) {
            $this->{_wsTransport} = lc($argv{$_});
        } elsif (/^-?radiusSecret$/i) {
            $this->{_radiusSecret} = $argv{$_};
        } elsif (/^-?controllerIp$/i) {
            $this->{_controllerIp} = $argv{$_}? lc($argv{$_}) : undef;
        } elsif (/^-?uplink$/i) {
            $this->{_uplink} = $argv{$_};
        } elsif (/^-?SNMPEngineID$/i) {
            $this->{_SNMPEngineID} = $argv{$_};
        } elsif (/^-?SNMPVersion$/i) {
            $this->{_SNMPVersion} = $argv{$_};
        } elsif (/^-?SNMPVersionTrap$/i) {
            $this->{_SNMPVersionTrap} = $argv{$_};
        } elsif (/^-?vlans$/i) {
            $this->{_vlans} = $argv{$_};
        } elsif (/^-?VoIPEnabled$/i) {
            $this->{_VoIPEnabled} = $argv{$_};
        } elsif (/^-?roles$/i) {
            $this->{_roles} = $argv{$_};
        } elsif (/^-?inlineTrigger$/i) {
            $this->{_inlineTrigger} = $argv{$_};
        } elsif (/^-?deauthMethod$/i) {
            $this->{_deauthMethod} = $argv{$_};
        } elsif (/^-?controllers$/i) {
            $this->{_controllers} = $argv{$_};
        }
        # customVlan members are now dynamically generated. 0 to 99 supported.
        elsif (/^-?(\w+)Vlan$/i) {
            $this->{'_'.$1.'Vlan'} = $argv{$_};
        }

    }

    use Data::Dumper;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    $logger->info("Dumping Cluster config");
    $logger->($this);
    return $this;

}

=item _deauthenticateMacWithSOAP

Method to deauthenticate a MAC with a SOAP Call.
Requires the SOAP API to be enabled on the MSM controller.

=cut

sub _deauthenticateMacWithSOAP {
    my ( $this, $mac ) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    $logger->info("Deauthenticating $mac with SOAP call");


    my $postdata 
        = qq(<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.procurve_mobility_msm.com/SOAP/API/1.7/">
       <soapenv:Header/>
       <soapenv:Body>
          <ns:ExecuteControlledWirelessDisassociateClient>
             <ns:macAddress>$mac</ns:macAddress>
          </ns:ExecuteControlledWirelessDisassociateClient>
       </soapenv:Body>
    </soapenv:Envelope>
    );

    my $HP_default_port = 448;
    my $soap_port = $this->{'_wsPort'} || $HP_default_port; 
    my @IPs = split '/,/', $this->{'_controllers'} ; # comma separated list of IPs
    my $authentication = '';
    if ( $this->{'_wsUser'} and $this->{'_wsPwd'} ) { 
        $authentication = $this->{'_wsUser'} . ':' . $this->{'_wsPwd'} . '@';
    }

    use WWW::Curl::Easy;
    my $curl_return_code;

    # until there is a way to find out on which controller a device associated, we have to 
    # try every controller in turn until we find one that returns an http 200. 
    TRYCONTROLLER: 
    for my $controller ( @IPs ) { 

        $logger->info("Attempting deauthentication on controller at $controller");

        my $curl = WWW::Curl::Easy->new;
        my $url = $this->{'_wsTransport'} . '://' .  $authentication . $controller . ':' .  $soap_port;
        my $response_body = '';
        open(my $fileb, ">", \$response_body);
        $curl->setopt(CURLOPT_URL, $url );
        $curl->setopt(CURLOPT_SSL_VERIFYPEER, 0) if $this->{'_wsTransport'} eq 'https'; # do not validate MSM certificate
        $curl->setopt(CURLOPT_HEADER, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, $postdata);
        $curl->setopt(CURLOPT_WRITEDATA,$fileb);
        
        $curl_return_code = $curl->perform;

        if ( $curl_return_code != 0 ) { 
            $logger->debug("Deauthentication failed for mac $mac on $url");
            $logger->debug("This is probably normal on a cluster.");
            $logger->debug("$response_body");
            return 0;
        } 
        else {
            $logger->info("Device $mac deauthenticated on $url");
            last TRYCONTROLLER;
        }
    }

    return $curl_return_code;
}


=item deauthTechniques

Return the reference to the deauth technique or the default deauth technique.
Note that the default here is HTTP (rather than SNMP as on the Standalone controller).

=cut

sub deauthTechniques {
    my ($this, $method) = @_;
    my $logger = Log::Log4perl::get_logger( ref($this) );
    my $default = $SNMP::HTTP;
    my %tech = (
        $SNMP::SNMP => \&deauthenticateMacDefault,
        $SNMP::SSH  => \&_deauthenticateMacWithSSH,
        $SNMP::HTTP => \&_deauthenticateMacWithSOAP,
        $SNMP::HTTPS => \&_deauthenticateMacWithSOAP,
    );

    if (!defined($method) || !defined($tech{$method})) {
        $method = $default;
    }
    return $method,$tech{$method};
}


=back

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
