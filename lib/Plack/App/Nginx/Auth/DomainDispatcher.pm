package Plack::App::Nginx::Auth::DomainDispatcher;
use parent qw(Plack::App::Nginx::Auth);
use Plack::Util::Accessor qw(
    default_host
    allowed_hosts
    denied_hosts
    separator
);

use strict;
use warnings;

use Net::IP;

use Nginx::Auth;

sub new {
    my $self = shift->SUPER::new(@_);

    my %defaults = (
        allowed_hosts => [ ],
        denied_hosts  => [ qw(224.0.0.0/4 ff00::/8) ],
    );
    $self->_map_hosts(sub {
        my($hosts, $key) = @_;
        $hosts ||= $defaults{$key};
        $hosts = [ $hosts ] unless ref $hosts;
        return $hosts unless $key eq 'allowed_hosts';
        push(@{$hosts}, $self->default_host) if $self->default_host;
        return $hosts;
    });

    $self->separator("@") unless $self->separator;

    return $self;
}

sub prepare_app {
    my $self = shift;

    $self->_map_hosts(sub {
        my($hosts, $key) = @_;
        $hosts = [] unless $hosts;
        $hosts = [ $hosts ] unless ref $hosts;
        return [ grep {$_} map {
            unless (ref) {
                $_ = Nginx::Auth::resolve_host($_) unless m(/);
                $_ = Net::IP->new($_);
            }
            $_;
        } @{$hosts} ];
    });

    unless (ref(my $sep = $self->separator) eq 'Regexp') {
        $sep = join('', @{$sep}) if ref $sep eq 'ARRAY';
        $sep = qr/[$sep]/;
        $self->separator($sep);
    }
}

sub call {
    my($self, $env) = @_;

    my $req = $self->new_request($env);
    return 403 unless $req->auth_username;

    my($user, $domain) = split($self->separator, $req->auth_username, 2);
    $domain ||= $self->default_host;
    return 403 unless $domain;

    my $server = Nginx::Auth::resolve_host($domain);
    return 403 unless $self->_check_hosts($server);

    return { 'server' => $server };
}

sub _map_hosts {
    my($self, $sub) = @_;

    foreach my $key (qw(allowed_hosts denied_hosts)) {
        $self->{$key} = $sub->($self->{$key}, $key);
    }
}

sub _check_hosts {
    my($self, $ip) = @_;

    return unless $ip;
    $ip = Net::IP->new($ip) unless ref $ip;

    my $found;
    foreach my $net (@{$self->allowed_hosts}) {
        my $r = $net->overlaps($ip);
        next unless defined $r;
        $found = $r != $Net::IP::IP_NO_OVERLAP;
        last if $found;
    }
    return unless $found;
    foreach my $net (@{$self->denied_hosts}) {
        my $r = $net->overlaps($ip);
        next unless defined $r;
        return if $r != $Net::IP::IP_NO_OVERLAP;
    }
    return 1;
}

1;
