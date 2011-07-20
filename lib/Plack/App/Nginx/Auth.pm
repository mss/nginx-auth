package Plack::App::Nginx::Auth;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(autowrap);

use strict;
use warnings;
use Carp qw();

use Plack::Middleware::Nginx::Auth;
use Plack::Middleware::Nginx::Auth::Request;

sub new_request {
    my($self, $env) = @_;
    Carp::croak(q{$env is required})
        unless defined $env && ref($env) eq 'HASH';
    return Plack::Middleware::Nginx::Auth::Request->new($env);
}

sub to_app {
    my($self) = @_;
    $self->prepare_app;
    $self->autowrap(1) unless defined $self->autowrap;
    return sub { $self->call(@_) } unless $self->autowrap;
    $self->autowrap(0);
    return Plack::Middleware::Nginx::Auth->wrap($self);
}

1;
