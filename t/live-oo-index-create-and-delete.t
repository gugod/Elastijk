#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use Test::More;


use Elastijk;

my $es = Elastijk->new( host => "localhost", port => "9200" );

my $test_index_name = "test_index_$$";
$es->create(
    index => {
        $test_index_name => {
            settings => {
                number_of_shards => 2,
                number_of_replicas => 0,
            },
            mappings => {
            }
        }
    }
);

$es->delete( index => $test_index_name );
$es->exists( index => $test_index_name );
