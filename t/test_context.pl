package Elastijk::Testing;
use strict;
use warnings;
use Elastijk;


my $HijkRequestArgs;
sub HijkRequestArgs { $HijkRequestArgs }
;{
    no warnings 'redefine';
    my $original = \&Elastijk::_build_hijk_request_args;
    *Elastijk::_build_hijk_request_args = sub {
        return $HijkRequestArgs = $original->(@_);
    }
};
1;
