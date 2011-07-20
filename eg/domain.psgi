use strict;
use warnings;
use lib qw(lib);
use Plack::App::Nginx::Auth::DomainDispatcher;
Plack::App::Nginx::Auth::DomainDispatcher->new(
    default_domain => 'example.com',
    allowed_hosts  => '192.0.43.10',
);
