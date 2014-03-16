#!/usr/bin/env perl
use v5.14;
use strict;
use Test::More;
use Elastijk;

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "TEST_LIVE is unset";
}


my $es = Elastijk->new(
    host   => "localhost",
    port   => "9200",
);

my $res = $es->uri_search(
    q => "git",
);

ok exists $res->{status}, "status";
ok exists $res->{body},   "body";

ok exists $res->{body}{hits},      "body.hits";
ok exists $res->{body}{took},      "body.took";
ok exists $res->{body}{timed_out}, "body.timed_out";
ok exists $res->{body}{_shards},   "body._shards";

done_testing;
