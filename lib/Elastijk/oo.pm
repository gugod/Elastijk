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
    my ($self, $type, $doc) = @_;

    if (ref($doc) eq 'ARRAY') {
        my $body = "";
        for my $d (@$doc) {
            if (ref($d) eq 'ARRAY') {
                $body .= $Elastijk::JSON->encode($d->[0]) . "\n"
                    . $Elastijk::JSON->encode($d->[1]) . "\n";
            }
            elsif (ref($d) eq 'HASH') {
                $body .= '{"index":{}}' . "\n"
                    . $Elastijk::JSON->encode($d) . "\n";
            }
        }

        my ($status, $res) = Elastijk::request_raw({
            host => $self->{host},
            port => $self->{port},
            method => "POST",
            index => $self->{index},
            type => $type,
            command => "_bulk",
            body => $body,
        });
        $res = $Elastijk::JSON->decode($res);
        return $res;
    }
    elsif (ref($doc) eq 'HASH') {
        my ($status, $res) = Elastijk::request({
            host => $self->{host},
            port => $self->{port},
            method => "POST",
            index => $self->{index},
            type  => $type,
            body => $doc,
        });
        return $res;
    }

    return undef;
}

sub get {
    my ($self, %spec) = @_;
    my $id = $spec{id};
    my ($status, $res) = Elastijk::request({
        host => $self->{host},
        port => $self->{port},
        method => "GET",
        index => $spec{index} || $self->{index},
        type => $spec{type} || $self->{type},
        command => $id
    });
    return $res;
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

sub search {
    my $self = shift;
    my %args = @_;
    my $search_type = delete $args{search_type};
    my ($status, $body) = Elastijk::request({
        method => "GET",
        host => $self->{host},
        port => $self->{port},
        $self->{index} ? ( index => $self->{index} ) : (),
        $self->{type}  ? ( type  => $self->{type}  ) : (),

        command => "_search",
        $search_type ? (
            uri_param => { search_type => $search_type }
        ) : (),

        body => \%args,
    });

    return {
        status => $status,
        body => $body,
    }
}


sub uri_search {
    my ($self, %args) = @_;
    my ($status, $body) = Elastijk::request({
        method => "GET",
        host => $self->{host},
        port => $self->{port},
        $self->{index} ? ( index => $self->{index} ) : (),
        $self->{type}  ? ( type  => $self->{type}  ) : (),

        command => "_search",
        uri_param => \%args,
    });

    return {
        status => $status,
        body => $body,
    }
}


1;
