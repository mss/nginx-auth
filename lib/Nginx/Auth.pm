package Nginx::Auth;

use 5.010;

use strict;
use warnings;
use Carp;

use URI::Escape;
use Socket;


sub prepare_env {
    my($env) = @_;

    my $nginx = "nginx.auth";
    my %nginx = (
        "$nginx.protocol"    => $env->{HTTP_AUTH_PROTOCOL} // "",

        "$nginx.username"    => uri_unescape($env->{HTTP_AUTH_USER} // ""),
        "$nginx.password"    => uri_unescape($env->{HTTP_AUTH_PASS} // ""),

        "$nginx.method"      => $env->{HTTP_AUTH_METHOD} // "",
        "$nginx.salt"        => $env->{HTTP_AUTH_SALT} // "",
        "$nginx.attempt"     => ($env->{HTTP_AUTH_LOGIN_ATTEMPT} // "0")*1,

        "$nginx.server.host" => "localhost",
        "$nginx.server.port" => resolve_port($env->{HTTP_AUTH_PROTOCOL}),

        "$nginx.client.ip"   => $env->{HTTP_CLIENT_IP} // "",
        "$nginx.client.host" => $env->{HTTP_CLIENT_HOST} // "",

        "$nginx.smtp.helo"   => $env->{HTTP_SMTP_HELO} // "",
        "$nginx.smtp.from"   => $env->{HTTP_SMTP_FROM} // "",
        "$nginx.smtp.to"     => $env->{HTTP_SMTP_TO} // "",
    );
    return wantarray ? %nginx : { %nginx };
}

sub merge_env {
    my($env) = @_;

    my %env = prepare_env($env);
    @{$env}{keys %env} = values %env;
}

# status
# error.message
# error.code
# server
# server.host
# server.port
# username
# password
# wait
sub prepare_header {
    my $env = shift;
    croak("expected HASH ref") unless ref $env eq 'HASH';

    my $status = @_ % 2 ? shift : undef;
    my %result = @_;

    given (ref $status) {
        when ('HASH') {
            %result = %{$status};
            $status = undef;
        }
        when (/./) {
            croak("unexpected $_ ref");
        }
    }
    $status = delete $result{'status'} if $result{'status'};
    given ($status) {
        when (undef) {
            $status = 502;
        }
        when (0) {
            $status = 401;
        }
        when (1) {
            $status = 203;
        }
    }

    my $message;
    $message = delete $result{'error'};
    $message = delete $result{'error.message'} if $result{'error.message'};
    $message = "" unless defined $message;
    $message = "" if $message =~ /^</;
    $message = "" if length($message) > 140;
    $message = "" if $message eq "OK";
    $message =~ y/\x20-\x7e//cd;
    given ($status) {
        when ([200, 201, 203, 204]) {
            $message = "OK";
        }
        when ([401, 403, 404, 410]) {
            $message ||= "Invalid Login or Password";
        }
        when ([408, 504]) {
            $message ||= "Nginx::Auth Timeout ($status)";
        }
        default {
            $message ||= "Nginx::Auth Error ($status)";
        }
    }
    $result{'status'} = $message;

    if ($result{'server'}) {
        delete($result{'server'}) =~ /^(?:(?:\[(?<host>.*?)\])|(?<host>.*?))(?::(?<port>.*))?$/;
        $result{'server.host'} = $+{'host'} if $+{'host'};
        $result{'server.port'} = $+{'port'} if $+{'port'};
    }
    foreach my $k (qw(host port)) {
        $result{"server.$k"} ||= $env->{"nginx.auth.server.$k"};
    }
    $result{'server'} = resolve_host(
        delete($result{'server.host'}));
    $result{'port'}   = resolve_port(
        delete($result{'server.port'}));

    foreach my $k (qw(username password)) {
        my $v = delete $result{$k};
        next unless $v;
        next if $v eq $env->{"nginx.auth.$k"};
        $result{substr($k, 0, 4)} = $v;
    }

    my %header;
    $result{'error-Code'} = delete $result{'error.code'};
    while (my($k, $v) = each %result) {
        next unless $k ~~ [qw(status server port user pass wait error-Code)];
        next unless $v;
        $header{"Auth-" . ucfirst($k)} = $v;
    }
    return wantarray ? %header : { %header };
}


sub resolve_port {
    my($port) = @_;

    return $port unless $port;
    $port = (getservbyname($port, "tcp"))[2] || $port;
    return $port;
}

sub resolve_host {
    my($host) = @_;

    return $host unless $host;
    return $host if $host =~ /^\d\.\d\.\d\.\d$/;
    return $host if $host =~ /:/;

    $host = gethostbyname($host);
    $host = inet_ntoa($host);

    return $host;
}

1;
