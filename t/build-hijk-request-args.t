#!/usr/bin/env perl

use strict;
use Test::More;
use Elastijk;

my @base_arg = (
    host => "127.0.0.1",
    port => "9200",
    method => "GET",
);
my @default = ( head => [ 'Content-Type' => 'application/json' ]);
my @tests = (
    [{}, { path => "/", @default }],
    [
        { command => "_stats" },
        { path => "/_stats", @default }
    ],
    [
        { command => "_search",
          uri_param => { search_type => "count" },
          body => '{"query":{"match_all":{}}}' },
        { path => "/_search",
          query_string => "search_type=count",
          body => '{"query":{"match_all":{}}}',
          @default }
    ],

    [
        { command => "_search",
          uri_param => { search_type => "scan" },
          body => '{"query":{"match_all":{}}}'  },
        { path => "/_search",
          query_string => "search_type=scan",
          body => '{"query":{"match_all":{}}}',
          @default }
    ],

    [
        { uri_param => { timeout => "3" },
          index => "foo",
          type  => "bar",
          id    => "42" },
        { path => "/foo/bar/42",
          query_string => "timeout=3",
          @default }
    ],

    [{
        index => "foo",
        type  => "bar",
        method => "HEAD",
    },{
        path => "/foo/bar",
        method => "HEAD",
        @default
    }],
);

for (@tests) {
    my $args = { @base_arg, %{$_->[0]} };
    my $expected_hijk_args = { @base_arg, %{$_->[1]} };

    my $hijk_args = Elastijk::_build_hijk_request_args($args);
    is_deeply(
        $hijk_args,
        $expected_hijk_args,
    );
}
done_testing;
