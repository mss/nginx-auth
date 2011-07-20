use 5.010;

use strict;
use warnings;
use lib qw(lib);

use Plack::Builder;

my $app = sub {
    my $env = shift;

    my $user = $env->{'nginx.auth.username'};
    return 403, {}, "Missing username" unless $user;
    return 403, {}, "Invalid username" unless $user =~ /^[a-z0-9]/i;

    return { server => "192.0.2." . ord(uc($user)) };
};

builder {
    enable "Plack::Middleware::Nginx::Auth";
    $app;
};
