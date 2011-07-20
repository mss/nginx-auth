package Plack::Middleware::Nginx::Auth::Request;
use parent qw(Plack::Request);

use strict;
use warnings;

sub auth_protocol    { $_[0]->env->{'nginx.auth.protocol'} }
sub auth_username    { $_[0]->env->{'nginx.auth.username'} }
sub auth_password    { $_[0]->env->{'nginx.auth.password'} }
sub auth_method      { $_[0]->env->{'nginx.auth.method'} }
sub auth_salt        { $_[0]->env->{'nginx.auth.salt'} }
sub auth_attempt     { $_[0]->env->{'nginx.auth.attempt'} }
sub auth_server_host { $_[0]->env->{'nginx.auth.server.host'} }
sub auth_server_port { $_[0]->env->{'nginx.auth.server.port'} }
sub auth_client_host { $_[0]->env->{'nginx.auth.client.host'} }
sub auth_client_ip   { $_[0]->env->{'nginx.auth.client.ip'} }
sub auth_smtp_helo   { $_[0]->env->{'nginx.auth.smtp.helo'} }
sub auth_smtp_from   { $_[0]->env->{'nginx.auth.smtp.from'} }
sub auth_smtp_to     { $_[0]->env->{'nginx.auth.smtp.to'} }

1;
