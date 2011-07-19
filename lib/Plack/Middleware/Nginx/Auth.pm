package Plack::Middleware::Nginx::Auth;
use parent qw(Plack::Middleware);

use 5.010;

use strict;
use warnings;

use Nginx::Auth;

sub call {
    my($self, $env) = @_;

    Nginx::Auth::merge_env($env);

    my($status, $result, $message) = $self->app->($env);
    given (ref $status) {
        when ('ARRAY') {
            ($status, $result, $message) = @{$status};
        }
        when ('HASH') {
            $result = $status;
            $status = 1;
        }
        when ('') {
            break;
        }
        default {
            $status = undef;
        }
    }
    $result ||= {};

    $result->{'status'}        = $status  if $status;
    $result->{'error.message'} = $message if $message;

    my %header = Nginx::Auth::prepare_header($env, $result);
    my @header = ( "Auth-Status" => delete $header{'Auth-Status'} );
    return [ 200, [ @header, %header ], [] ];
}

1;
