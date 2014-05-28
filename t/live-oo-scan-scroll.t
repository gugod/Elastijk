#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Set env TEST_LIVE=1 to run this test."
}

use Elastijk;

my $test_index_name = "test_index_$$".rand();
my $es = Elastijk->new(host => 'localhost', port => '9200', index => $test_index_name );
## create the index, and index some documents.
$es->put(
    body => {
        settings => { index => {number_of_replicas => 0, number_of_shards => 1} },
        mappings => { somedata => { properties => { somestr => { type => "string" }, someint => { type => "long" }}}}
    }
);

## create 5000 documents
$es->post(
    type => 'somestr',
    body => {
        # U+1F30x ~ U+1F56x
        somestr => join("", map { chr(rand()*260+0x1F300) } (0..(10+rand()*128))),
        someint => int(rand()*2**16),
    }
) for (0..4999);

sleep 2; # wait for refresh.
is $es->count(), 5000, "count 5000 documents";

## finally, testing scan_scroll
my $count = 0;
$es->scan_scroll(
    body => { size => 1000, query => { match_all => {} } },
    on_response => sub {
        $count++;
        return 1;
    }
);
is $count, 5, "on_response is called exactly 5 times.";

## delete the index
$es->delete( index => $test_index_name );

done_testing;
