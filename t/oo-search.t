#!/usr/bin/env perl
use v5.14;
use strict;
use Test::More;
use Elastijk;
use FindBin;
require "$FindBin::Bin/test_context.pl";

unless ($ENV{TEST_LIVE}) {
    plan skip_all => "TEST_LIVE is unset";
}


my $es = Elastijk->new(
    host   => "localhost",
    port   => "9200",
);

my $res = $es->search(
    search_type => "query_then_fetch",
    query => {
        match => {
            _all => "git"
        }
    }
);

my $req = Elastijk::Testing::HijkRequestArgs();
ok exists $req->{query_string};
is $req->{query_string}, "search_type=query_then_fetch";

ok exists $res->{status}, "status";
ok exists $res->{body},   "body";

ok exists $res->{body}{hits},      "body.hits";
ok exists $res->{body}{took},      "body.took";
ok exists $res->{body}{timed_out}, "body.timed_out";
ok exists $res->{body}{_shards},   "body._shards";

done_testing;
