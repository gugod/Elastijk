package Elastijk;
use strict;
use warnings;
our $VERSION = "0.01";

use JSON ();
use URI::Escape qw(uri_escape);
use Hijk;

our $JSON = JSON->new->utf8;

sub _build_hijk_request_args {
    my $args = $_[0];
    my ($path, $qs, $uri_param);
    $path = "/". join("/", grep { defined } @{$args}{qw(index type command)});
    if ($args->{uri_param}) {
        $qs =  join('&', map { uri_escape($_) . "=" . uri_escape($args->{uri_param}{$_}) } keys %{$args->{uri_param}});
    }

    return {
        method => $args->{method} || 'GET',
        host   => $args->{host}   || 'localhost',
        port   => $args->{port}   || '9200',
        !$path ?() :(
            path   => $path
        ),
        !$qs ?() :(
            query_string => $qs
        ),
        !$args->{body} ?() :(
            body => (ref($args->{body}) ? $JSON->encode($args->{body}) : $args->{body})
        ),
    }
}

sub request {
    my $arg = $_[0];
    if ($arg->{body}) {
        $arg = {%{$_[0]}};
        $arg->{body} = $JSON->encode( $arg->{body} );
    }
    my ($status, $res_body) = request_raw($arg);
    $res_body = $res_body ? $JSON->decode($res_body) : undef;
    return $status, $res_body;
}

sub request_raw {
    my $args = _build_hijk_request_args($_[0]);
    my $res = Hijk::request($args);
    return $res->{status}, $res->{body};
}


1;

=encoding utf-8

=head1 NAME

Elastijk - A specialized ElasticSearch client.

=head1 SYNOPSIS

    use Elastijk;

=head1 DESCRIPTION

=head1 LICENSE

Copyright (C) Kang-min Liu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=cut
