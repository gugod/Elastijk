#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Set env TEST_LIVE=1 to run this test."
}


use Elastijk;

my $es = Elastijk->new( host => "localhost", port => "9200" );
my $test_index_name = "test_index_$$";
my $res;

# Check if the index exists
$res = $es->exists( index => $test_index_name );
ok !$res, "The index $test_index_name should not exist because we have not created it yet.";

# Create an index with settings and mappings.
$res = $es->create(
    index => {
        $test_index_name => {
            settings => {
                index => {
                    number_of_shards => 2,
                    number_of_replicas => 0,
                }
            },
            mappings => {
                cafe => {
                    properties => {
                        name => { type => "string" },
                        address => { type => "string" }
                    }
                }
            }
        }
    }
);

# Check if the index exists
$res = $es->exists( index => $test_index_name );
ok $res, "The index $test_index_name exists, because we just created it.";

# Check if the index exists
$res = $es->exists( index => $test_index_name, type => "cafe" );
ok $res, "The type 'cafe' exists in the index ${test_index_name}, because we specified the mapping when creating the index.";

# Check if the index exists
$res = $es->exists( index => $test_index_name, type => "printer" );
ok !$res, "The type 'printer' does not exists in the index ${test_index_name} (as expected), because we did not specify it in the index.";


# Delete the index.
$res = $es->delete( index => $test_index_name );

# Check if the index exists
$res = $es->exists( index => $test_index_name );
ok !$res, "The index $test_index_name does not exist, because we just deleted it.";

done_testing;
