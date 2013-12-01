package Elastijk::oo;
use strict;
use warnings;
use Elastijk;

sub new {
    my $class = shift;
    return bless { host => "localhost", port => "9200", @_ }, $class;
}

{
    no warnings 'redefine';
    *Elastijk::new = *Elastijk::oo::new;
};

sub index {
    my ($self, %spec) = @_;
}

sub exists {
    my ($self, %spec) = @_;

    if ( !ref($spec{index}) ) {
        my ($status, undef) = Elastijk::request({
            host => $self->{host},
            port => $self->{port},
            method => "HEAD",
            index => $spec{index},
            !$spec{type} ?() : (
                type => $spec{type}
            ),
        });

        return $status eq '200';
    }

    return undef;
}

sub create {
    my ($self, %spec) = @_;
    my $res = {};
    for my $index_name ( keys %{ $spec{index} } ) {
        my ($status, $body) = Elastijk::request({
            host => $self->{host},
            port => $self->{port},
            index => $index_name,
            method => "PUT",
            body => $spec{index}{$index_name}
        });
        $res->{$index_name} = { status => $status, body => $body }
    }

    return $res;
}

sub delete {
    my ($self, %spec) = @_;
    my $res = {};
    my $index_name = $spec{index};
    my ($status, $body) = Elastijk::request({
        host => $self->{host},
        port => $self->{port},
        index => $index_name,
        method => "DELETE"
    });
    $res->{$index_name} = { status => $status, body => $body };
    return $res;
}


1;
