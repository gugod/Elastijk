package Elastijk;
use strict;
use warnings;

use JSON ();
use URI::Escape qw(uri_escape);
use Hijk;

sub _build_hijk_request {
    my $args = $_[0];
    my ($path, $qs);
    $path = "/". join("/", grep { defined } delete @{$args}{qw(index type command)});
    if (my $uri_param = $args->{uri_param}) {
        $qs =  join('&', map { uri_escape($_) . "=" . uri_escape($uri_param->{$_}) } keys %$uri_param);
    }
    return {
        method => $args->{method} || 'GET',
        host   => $args->{host}   || 'localhost',
        port   => $args->{port}   || '9200',
        $path ? ( path   => $path ):(),
        $qs   ? ( query_string => $qs ):(),
        $args->{body} ? ( body => JSON::encode_json($args->{body}) ) : (),
    }
}

sub request {
    return JSON::decode_json Hijk::request( _build_hijk_request($_[0]) );
}

1;
