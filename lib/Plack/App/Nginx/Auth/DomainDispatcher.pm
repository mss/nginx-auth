package Plack::App::Nginx::Auth::DomainDispatcher;
use parent qw(Plack::App::Nginx::Auth);
use Plack::Util::Accessor qw(
    default_host
    default_port
    allowed_hosts
    allowed_ports
    denied_hosts
    denied_ports
    separator
    user_filter
);

use strict;
use warnings;

use Net::IP;

use Nginx::Auth;

sub new {
    my $self = shift->SUPER::new(@_);

    my %defaults = (
        allowed_hosts => [ ],
        allowed_ports => [ qw(smtp smtps submission imap imaps pop3 pop3s) ],
        denied_hosts  => [ qw(224.0.0.0/4 ff00::/8) ],
        denied_ports  => [ ],
    );
    $self->_map_hosts(sub {
        my($hosts, $key) = @_;
        $hosts ||= $defaults{$key};
        $hosts = [ $hosts ] unless ref $hosts;
        return $hosts unless $key eq 'allowed_hosts';
        push(@{$hosts}, $self->default_host) if $self->default_host;
        return $hosts;
    });
    $self->_map_ports(sub {
        my($ports, $key) = @_;
        $ports ||= $defaults{$key};
        $ports = [ $ports ] unless ref $ports;
        return $ports;
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
    $self->_map_ports(sub {
        my($ports, $key) = @_;
        $ports = [] unless $ports;
        $ports = [ $ports ] unless ref $ports;
        return [ grep {$_} map {
            $_ = Nginx::Auth::resolve_port($_);
        } @{$ports} ];
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

    $user = ($self->user_filter || sub { $req->auth_username })->($user, $domain);
    return 403 unless defined $user;

    if (my $port = $self->default_port) {
        $port = $port->{$env->{'nginx.auth.protocol'}} if ref $port eq 'HASH';
        $server .= ":" . Nginx::Auth::resolve_port($port) if $port;
    }

    return {
        'server'   => $server,
        'username' => $user,
    };
}

sub _map_hosts {
    my($self, $sub) = @_;

    foreach my $key (qw(allowed_hosts denied_hosts)) {
        $self->{$key} = $sub->($self->{$key}, $key);
    }
}

sub _map_ports {
    my($self, $sub) = @_;

    foreach my $key (qw(allowed_ports denied_ports)) {
        $self->{$key} = $sub->($self->{$key}, $key);
    }
}

sub _check_hosts {
    my($self, $host) = @_;

    return unless $host;
    $host = Net::IP->new($host) unless ref $host;

    my $found;
    foreach my $net (@{$self->allowed_hosts}) {
        my $r = $net->overlaps($host);
        next unless defined $r;
        $found = $r != $Net::IP::IP_NO_OVERLAP;
        last if $found;
    }
    return unless $found;
    foreach my $net (@{$self->denied_hosts}) {
        my $r = $net->overlaps($host);
        next unless defined $r;
        return if $r != $Net::IP::IP_NO_OVERLAP;
    }
    return 1;
}

sub _check_ports {
    my($self, $port) = @_;

    return unless grep { $_ eq $port } @{$self->allowed_ports};
    return     if grep { $_ eq $port } @{$self->denied_ports};
    return 1;
}

1;
