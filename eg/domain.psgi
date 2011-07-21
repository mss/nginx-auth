use strict;
use warnings;
use lib qw(lib);
use Plack::App::Nginx::Auth::DomainDispatcher;
Plack::App::Nginx::Auth::DomainDispatcher->new(
    separator      => qr/[^a-zA-Z0-9._-]/,
    user_filter    => sub { return join('@', @_) },
    default_host   => 'example.com',
    allowed_hosts  => 'localhost',
);
