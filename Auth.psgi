use 5.010;

use strict;
use warnings;

use lib qw(lib);

use Data::Dumper;

use Plack::Builder;

my $app = sub {
    my $env = shift;
    given ($env->{'nginx.auth.username'}) {
        when ([qw(foo bar)]) {
            return { server => "192.168.0.1" };
        }
        when ([qw(baz)]) {
            return { server => "192.168.0.2" };
        }
        default {
            return 403, {}, "User $_ not Found";
        }
    }
};

builder {
    enable "Plack::Middleware::Nginx::Auth";
    $app;
};
