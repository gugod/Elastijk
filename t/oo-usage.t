#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Elastijk;

my $es = Elastijk->new( host => "es.example.com", port => 9200 );
my $request_content;

no warnings 'redefine';
sub Hijk::request {
    $request_content = $_[0];
    return {}
}
use warnings;

subtest "The request structure for _search command" => sub {
    my $q = { query => { match_all => {} } };
    my $q_json = $Elastijk::JSON->encode($q);

    $es->search(index => "foo", type => "bar", body => $q);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/foo/bar/_search",
        body  => $q_json,
    });

    $es->search(body => $q);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/_search",
        body  => $q_json,
    });

    $es->search(index => "foo,baz", body => $q);
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/foo,baz/_search",
        body  => $q_json,
    });

    $es->search(index => "foo", uri_param => { q => "bar" });
    is_deeply( $request_content, {
        host => "es.example.com",
        port => 9200,
        method => "GET",
        path  => "/foo/_search",
        query_string => "q=bar",
    });
};

done_testing;
