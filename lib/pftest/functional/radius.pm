package pftest::functional::radius;

# a package containing various methods to test radius request/replies

use strict;
use warnings;
use Test::More qw(no_plan);
use Moose;
use Net::IP;

has radius_server   => ( is => "ro", required => 1 );
has ip              => ( is => "rw", required => 1 );
has shared_secret   => ( is => "ro", required => 1 );
has timeout         => ( is => "rw", isa      => 'Int', default => 10 );
has ansible_context => ( is => "ro", required => 0 );

sub match_cisco_avpair {
    my ( $self, $avpair ) = @_;
    return qr/
            rad_recv:\sAccess-Accept\spacket\sfrom\shost.+
            \s+Cisco-AVPair\s=\s"$avpair".+
        /sx;
}

sub match_eapol_vlan {
    my ( $self, $vlan ) = @_;

    my $ascii_hex = unpack( "H*", $vlan );
    return qr/
            \s+RADIUS\s+message:\s+code=2\s+\(Access-Accept\).+
            \s+Attribute\s+81\s+\(Tunnel-Private-Group-Id\).+
            \s+Value:\s+$ascii_hex
        /sx;
}

sub check_eapol_accept {
    my $self = shift;
    my %attributes = (
        SSID           => 'SSID',
        MAC            => '02:00:00:00:00:01',    # fake MAC
        SWITCH_MAC     => '02:00:00:00:00:02',    # fake called mac
        NAS_IP_Address => undef,
        vlan           => undef,
        conf           => undef,
    );
    %attributes  = (%attributes, @_);
    return undef unless defined $attributes{'conf'};

    my $eapoltest_cmd = "eapol_test \
                -c $attributes{'conf'} \
                -s $self->{shared_secret} \
                -a $self->{radius_server} \
                -r 1 \
                -t $self->{timeout} \
                -N30:s:$attributes{'SWITCH_MAC'}:$attributes{'SSID'} \
                -N31:s:$attributes{'MAC'}";

    if ( defined $attributes{'NAS_IP_Address'} ) {
        my $hex_ip = Net::IP->new( $attributes{'NAS_IP_Address'} )->hexip();
        $eapoltest_cmd .= " -N4:x:$hex_ip ";
    }

    $eapoltest_cmd =~ s/\n/ /g; # strip newlines

    my $output = `$eapoltest_cmd`;
    like(
        $output,
        $self->match_eapol_vlan( $attributes{'vlan'} ),
        "eapol_test returns the correct vlan $attributes{'vlan'}"
    );

}


sub check_macauth_accept {
    my $self       = shift;
    my %attributes = (
        vlan         => undef,
        Cisco_AVPair => undef,
        input        => undef,
    );
    %attributes = @_;
    return undef unless defined $attributes{'input'};

    if ( defined $attributes{'Cisco_AVPair'} ) {
        like(
            $self->radclient_auth( $attributes{'input'} ),
            $self->match_cisco_avpair( $attributes{'Cisco_AVPair'} ),
"radius replies with access-accept and correct VOIP vsa $attributes{'Cisco_AVPair'}"
        );
    }
    if ( defined $attributes{'vlan'} ) {
        return undef;    # TODO
    }
}

sub radclient_auth {
    my ( $self, $input ) = @_;

    my $radclient_cmd =
"radclient -t $self->{timeout} -x $self->{radius_server} auth $self->{shared_secret}";
    use IPC::Open2;
    my $pid = open2( \*CHLD_OUT, \*CHLD_IN, $radclient_cmd )
      or die "open2() failed $!";

    print CHLD_IN $input;
    close CHLD_IN;    # flush the buffer
    my $output;
    {
        local $/;
        $output = <CHLD_OUT>;
    }
    waitpid( $pid, 0 );
    return $output;
}

1;
