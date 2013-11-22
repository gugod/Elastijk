#!/usr/bin/env perl

use strict;
use Test::More;

use Elastijk;

my $res;
my @base_arg = (
    host => "127.0.0.1",
    port => "9200",
    method => "GET",
);
my @tests = (
    [],
    [ command => "_search",
       uri_param => {
           search_type => "count",
       },
       body => {
           query => { match_all => {} }
       }
   ]
);

for (@tests) {
    $res = Elastijk::request({ @base_arg, @$_ });
    is ref($res), 'HASH', JSON::encode_json($res);
}
done_testing;
