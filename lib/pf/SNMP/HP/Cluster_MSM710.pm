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
    my @IPs = @{ $this->{'_cluster_ips'} };
    unless ( scalar @IPs > 0 ) {
        $logger->error("cluster_ips is invalid. Check your configuration in switches.conf");
        return 0;
    }

    my $authentication = '';
    if ( $this->{'_wsUser'} and $this->{'_wsPwd'} ) { 
        $authentication = $this->{'_wsUser'} . ':' . $this->{'_wsPwd'} . '@';
    }

    use WWW::Curl::Easy;
    my ( $curl_return_code, $curl_info );

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
        $curl_info = $curl->getinfo(CURLINFO_HTTP_CODE); # or CURLINFO_RESPONSE_CODE depending on libcurl version

        if ( $curl_return_code != 0 or $curl_info != 200 ) { 
            $logger->debug("Deauthentication failed for mac $mac on $url");
            $logger->debug("This is probably normal on a cluster.");
            $logger->debug("$response_body");
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
