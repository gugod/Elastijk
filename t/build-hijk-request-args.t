#!/usr/bin/env perl

use strict;
use Test::More;
use Elastijk;

my @base_arg = (
    host => "127.0.0.1",
    port => "9200",
    method => "GET",
);
my @tests = (
    [{}, { path => "/" }],
    [
        { command => "_stats" },
        { path => "/_stats" }
    ],
    [
        { command => "_search",
          uri_param => { search_type => "count" },
          body => { query => { match_all => {} } } },
        { path => "/_search",
          query_string => "search_type=count",
          body => '{"query":{"match_all":{}}}' }
    ],
    [
        { command => "_search",
          uri_param => { search_type => "count" },
          body => { query => { "match_all" => {} } }  },
        { path => "/_search",
          query_string => "search_type=count",
          body => '{"query":{"match_all":{}}}'  }
    ],

    [
        { command => "_search",
          uri_param => { search_type => "count" },
          body => '{"query":{"match_all":{}}}'  },
        { path => "/_search",
          query_string => "search_type=count",
          body => '{"query":{"match_all":{}}}'  }
    ],
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
