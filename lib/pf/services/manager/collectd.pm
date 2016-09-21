package pf::services::manager::collectd;

=head1 NAME

pf::services::manager::collectd

=cut

=head1 DESCRIPTION

pf::services::manager::collectd
collectd daemon manager module for PacketFence.

=cut

use strict;
use warnings;
use pf::file_paths qw(
    $install_dir
    $conf_dir
    $log_dir
    $var_dir
);
use pf::util;
use pf::config qw(
    %Config
    $OS
    $management_network
);
use Moo;
use Sys::Hostname;

extends 'pf::services::manager';

has '+name'     => ( default => sub {'collectd'} );
has '+optional' => ( default => sub {1} );
has startDependsOnServices => ( is => 'ro', default => sub { [qw(carbon-cache carbon-relay)] } );

has '+launcher' => (
    default => sub {
        "sudo %1\$s -P $install_dir/var/run/collectd.pid -C $install_dir/var/conf/collectd.conf";
    }
);

has configFilePath => (is => 'rw', builder => 1, lazy => 1);

has configTemplateFilePath => (is => 'rw', builder => 1, lazy => 1);

sub generateConfig {
    my ($self) = @_;
    my $vars = $self->createVars();
    my $tt = Template->new(ABSOLUTE => 1);
    $tt->process($self->configTemplateFilePath, $vars, $self->configFilePath) or die $tt->error();
}

sub createVars {
    my ($self) = @_;
    my %vars;
    $vars{'OS'} = $OS;
    $vars{'install_dir'} = "$install_dir";
    $vars{'log_dir'}     = "$log_dir";
    $vars{'management_ip'}
        = defined( $management_network->tag('vip') )
        ? $management_network->tag('vip')
        : $management_network->tag('ip');
    $vars{'graphite_host'} = "$Config{'monitoring'}{'graphite_host'}";
    $vars{'graphite_port'} = "$Config{'monitoring'}{'graphite_port'}";
    $vars{'hostname'}      = hostname;
    $vars{'db_host'}       = "$Config{'database'}{'host'}";
    $vars{'db_username'}   = "$Config{'database'}{'user'}";
    $vars{'db_password'}   = "$Config{'database'}{'pass'}";
    $vars{'db_database'}   = "$Config{'database'}{'db'}";
    $vars{'httpd_portal_modstatus_port'} = "$Config{'ports'}{'httpd_portal_modstatus'}";

    return \%vars;
}

sub _build_configFilePath {
    my ($self) = @_;
    return "$var_dir/conf/" . $self->name . ".conf";
}

sub _build_configTemplateFilePath {
    my ($self) = @_;
    return "$conf_dir/monitoring/" . $self->name . ".tt";
}

1;
