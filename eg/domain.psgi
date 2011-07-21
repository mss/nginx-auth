use strict;
use warnings;
use lib qw(lib);
use Plack::App::Nginx::Auth::DomainDispatcher;
Plack::App::Nginx::Auth::DomainDispatcher->new(
    default_host   => 'example.com',
    allowed_hosts  => 'localhost',
);
