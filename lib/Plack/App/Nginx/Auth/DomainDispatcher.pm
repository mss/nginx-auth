package Plack::App::Nginx::Auth::DomainDispatcher;
use parent qw(Plack::App::Nginx::Auth);
use Plack::Util::Accessor qw(default_host allowed_hosts);

use strict;
use warnings;

use Net::IP;

use Nginx::Auth;

sub prepare_app {
    my($self) = @_;

    my $hosts = $self->allowed_hosts;
    $hosts ||= [];
    $hosts = [ $hosts ] unless ref $hosts;
    map { $_ = Net::IP->new($_) or die Net::IP::Error() } @{$hosts};
    $self->allowed_hosts($hosts);
}

sub call {
    my($self, $env) = @_;

    my $req = $self->new_request($env);
    return 403 unless $req->auth_username;

    my($user, $domain) = split(/[@+%]/, $req->auth_username, 2);
    $domain ||= $self->default_host;
    return 403 unless $domain;

    my $server = Nginx::Auth::resolve_host($domain);
    return 403 unless $server;
    my $ip = Net::IP->new($server);
    foreach my $net (@{$self->allowed_hosts}) {
        my $r = $net->overlaps($ip);
        next unless defined $r;
        if ($r != $Net::IP::IP_NO_OVERLAP) {
            $ip = undef;
            last;
        }
    }
    return 403 if $ip;

    return { 'server' => $server };
}

1;
