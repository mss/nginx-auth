package Plack::App::Nginx::Auth::DomainDispatcher;
use parent qw(Plack::App::Nginx::Auth);
use Plack::Util::Accessor qw(default_domain);

use strict;
use warnings;

use Nginx::Auth;

sub call {
    my($self, $env) = @_;

    my $req = $self->new_request($env);
    return 0 unless $req->auth_username;

    my($user, $domain) = split(/[@+%]/, $req->auth_username, 2);
    $domain ||= $self->default_domain;
    return 0 unless $domain;

    my $host = Nginx::Auth::resolve_host($domain);
    return 0 unless $host;

    return { 'server' => $host };
}

1;
