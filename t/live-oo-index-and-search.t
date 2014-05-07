#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "Set env TEST_LIVE=1 to run this test."
}


use Elastijk;

my $res;
my $test_index_name = "test_index_$$";

my $es = Elastijk->new(
    host => 'localhost',
    port => '9200',
    index => $test_index_name,
);

## create the index, and index some documents.
$es->create(
    index => {
        $test_index_name => {
            settings => {
                index => {
                    number_of_replicas => 0,
                    number_of_shards => 1
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

subtest "index a single document." => sub {
    my $source = {
        name => "daily",
        address => "No. 42, routine road.",
    };

    my $res = $es->index(cafe => $source);
    is ref($res), 'HASH';
    ok defined($res->{_id});

    $res = $es->get( type => "cafe", id => $res->{_id} );
    is_deeply($res->{_source}, $source);
};

subtest "index 2 documents" => sub {
    my $sources = [{
        name => "autumn",
        address => "No. 42, leaf road.",
    },{
        name => "ink",
        address => "No. 42, black street.",
    }];
    $res = $es->index(cafe => $sources);
    is ref($res), 'HASH';
    is ref($res->{items}), 'ARRAY';

    for(my $i = 0; $i < @$sources; $i++) {
        my $source = $sources->[$i];
        my ($action, $res2) = (%{$res->{items}[$i]});
        is $action, 'create';
        my $res3 = $es->get( type => "cafe", id => $res2->{_id} );
        is_deeply($res3->{_source}, $source);
    }
};

subtest "index 2 documents with the value of 'type' attribute in the object." => sub {
    my $es = Elastijk->new(
        host => 'localhost',
        port => '9200',

        index => $test_index_name,
        type => "cafe",
    );

    pass ref($es);

    my $sources = [{
        name => "where",
        address => "No. 42, that road.",
    },{
        name => "leave",
        address => "No. 42, the street.",
    }];

    $res = $es->index($sources);
    is ref($res), 'HASH';
    is ref($res->{items}), 'ARRAY';

    for(my $i = 0; $i < @$sources; $i++) {
        my $source = $sources->[$i];
        my ($action, $res2) = (%{$res->{items}[$i]});
        is $action, 'create';
        my $res3 = $es->get( type => "cafe", id => $res2->{_id} );
        is_deeply($res3->{_source}, $source);
    }
};

subtest "index single/multiple documents, with extra attributes" => sub {
    local $TODO = "The test for response is incomplete.";

    $res = $es->index(
        cafe => [
            [{ id => "morelax", routing => "taipei"},
             { name => "morelax", address => "No. 60, hangout road."}],

            [{ id => "lotus", routing => "hsinchu" },
             { name => "Lotus", address => "No. 12, flower market." }],

            [{ id => "yeh", routing => "taichung" },
             { name => "Yeh", address => "No. 1, processor lane." }]
        ]
    );
    is ref($res), 'HASH';
    is ref($res->{items}), 'ARRAY';
};

# done testing. delete the index.
$es->delete( index => $test_index_name );

done_testing;
