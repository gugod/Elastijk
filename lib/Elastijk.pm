package Elastijk;
use strict;
use warnings;
our $VERSION = "0.01";

use JSON ();
use URI::Escape qw(uri_escape);
use Hijk;

sub _build_hijk_request_args {
    my $args = $_[0];
    my ($path, $qs, $body);
    $path = "/". join("/", grep { defined } delete @{$args}{qw(index type command)});
    if (my $uri_param = $args->{uri_param}) {
        $qs =  join('&', map { uri_escape($_) . "=" . uri_escape($uri_param->{$_}) } keys %$uri_param);
    }

    $body = $args->{body};
    $body = JSON::encode_json($body)
        if ref($body);

    return {
        method => $args->{method} || 'GET',
        host   => $args->{host}   || 'localhost',
        port   => $args->{port}   || '9200',
        $path ? ( path   => $path ):(),
        $qs   ? ( query_string => $qs ):(),
        $body ? ( body => $body ):()
    }
}

sub request {
    my $res = Hijk::request( _build_hijk_request_args($_[0]) );
    return $res->{status}, ($res->{body} && substr($res->{body},0,1) eq "{") ? JSON::decode_json($res->{body}) : undef;
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
