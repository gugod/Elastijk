package Elastijk;
use strict;
use warnings;

use JSON ();
use URI::Escape qw(uri_escape);
use Hijk;

sub request {
    my $args = $_[0];
    my $uri_param = $args->{uri_param};
    my $path = "/". join("/", grep { defined } delete @{$args}{qw(index type command)});
    my $qs =  join('&', map { uri_escape($_) . "=" . uri_escape($uri_param->{$_}) } keys %$uri_param);
    return JSON::decode_json Hijk::request({
        method => $args->{method} || 'GET',
        host   => $args->{host}   || 'localhost',
        port   => $args->{port}   || '9200',
        path   => $path,
        query_string => $qs,
        body => JSON::encode_json($args->{body}),
    });
}

1;
