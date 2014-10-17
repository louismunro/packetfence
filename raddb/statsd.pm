#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
#
#


use strict;
use warnings;
# use ...
# This is very important ! Without this script will not get the filled hashesh from main.
use vars qw(%RAD_REQUEST %RAD_REPLY %RAD_CHECK);

# This is hash wich hold original request from radius
#my %RAD_REQUEST;
# In this hash you add values that will be returned to NAS.
#my %RAD_REPLY;
#This is for check items
#my %RAD_CHECK;

#
# This the remapping of return values
#
use constant    RLM_MODULE_REJECT=>    0;#  /* immediately reject the request */
use constant	RLM_MODULE_FAIL=>      1;#  /* module failed, don't reply */
use constant	RLM_MODULE_OK=>        2;#  /* the module is OK, continue */
use constant	RLM_MODULE_HANDLED=>   3;#  /* the module handled the request, so stop. */
use constant	RLM_MODULE_INVALID=>   4;#  /* the module considers the request invalid. */
use constant	RLM_MODULE_USERLOCK=>  5;#  /* reject the request (user is locked out) */
use constant	RLM_MODULE_NOTFOUND=>  6;#  /* user not found */
use constant	RLM_MODULE_NOOP=>      7;#  /* module succeeded without doing anything */
use constant	RLM_MODULE_UPDATED=>   8;#  /* OK (pairs modified) */
use constant	RLM_MODULE_NUMCODES=>  9;#  /* How many return codes there are */


use lib '/usr/local/pf/lib';
use Sys::Hostname;
use Etsy::StatsD;

# Edit these constants to point to your statsd server.
use constant PacketFence_StatsD_Host =>  '127.0.0.1';
use constant PacketFence_StatsD_Port =>  8125;  

my $statsd = Etsy::StatsD->new(
    PacketFence_StatsD_Host,
    PacketFence_StatsD_Port,
);

my $shortname = (split('\.', hostname))[0];
my $graphite_namespace = 'pf.' . $shortname . '.radius.';

# Function to handle authorize
sub authorize {
    $statsd->increment( $graphite_namespace . 'authorize');
	return RLM_MODULE_OK;
}

# Function to handle authenticate
sub authenticate {
    $statsd->increment( $graphite_namespace . 'authenticate');
}

# Function to handle preacct
sub preacct {
    $statsd->increment( $graphite_namespace . 'preacct');
	return RLM_MODULE_OK;
}

# Function to handle accounting
sub accounting {
    $statsd->increment( $graphite_namespace . 'accounting');
	return RLM_MODULE_OK;
}

# Function to handle checksimul
sub checksimul {
	return RLM_MODULE_NOOP;
}

# Function to handle pre_proxy
sub pre_proxy {
    $statsd->increment( $graphite_namespace . 'pre_proxy');
	return RLM_MODULE_OK;
}

# Function to handle post_proxy
sub post_proxy {
    $statsd->increment( $graphite_namespace . 'post_proxy');
	return RLM_MODULE_OK;
}

# Function to handle post_auth
sub post_auth {
    $statsd->increment( $graphite_namespace . 'post_auth');
	return RLM_MODULE_OK;
}

# Function to handle xlat
sub xlat {
    return RLM_MODULE_NOOP;
}

# Function to handle detach
sub detach {
    return RLM_MODULE_NOOP;
}

sub log_request_attributes {
	# This shouldn't be done in production environments!
	# This is only meant for debugging!
	for (keys %RAD_REQUEST) {
		&radiusd::radlog(1, "RAD_REQUEST: $_ = $RAD_REQUEST{$_}");
	}
}
