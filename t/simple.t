#!/usr/bin/env perl

use strict;
use Test::More;

use Elastijk;

my $req_arg = {
    host => "127.0.0.1",
    port => "9200",
    method => "GET",
    command => "_search",
    uri_param => {
        search_type => "count",
    },
    body => {
        query => { match_all => {} }
    }
};

my $res = Elastijk::request($req_arg);

is ref($res), 'HASH', JSON::encode_json($res);

done_testing;
