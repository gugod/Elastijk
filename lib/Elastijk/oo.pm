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
    *Elastijk::new = sub { shift; Elastijk::oo->new(@_) };
};

sub request {
    my ($self, %args) = @_;
    $args{$_} ||= $self->{$_} for grep { exists $self->{$_} } qw(host port index type);
    return Elastijk::request(\%args);
}

sub request_raw {
    my ($self, %args) = @_;
    $args{$_} ||= $self->{$_} for grep { exists $self->{$_} } qw(host port index type);
    return Elastijk::request_raw(\%args);
}

sub index {
    my $self = shift;
    my $doc  = pop;
    my $type = @_ ? $_[0] : $self->{type};

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

        my ($status, $res) = $self->request_raw(
            method => "POST",
            defined($type) ? ( type => $type ) : (),
            command => "_bulk",
            body => $body,
        );
        $res = $Elastijk::JSON->decode($res);
        return $res;
    } elsif (ref($doc) eq 'HASH') {
        my ($status, $res) = $self->request(
            method => "POST",
            defined($type) ? ( type => $type ) : (),
            body => $doc,
        );
        return $res;
    }

    return undef;
}

sub get {
    my ($self, %spec) = @_;
    my ($status, $res) = $self->request(
        exists($spec{index}) ? ( index => $spec{index} ) : (),
        exists($spec{type})  ? ( type  => $spec{type}  ) : (),
        command => $spec{id},
    );
    return $res;
}

sub exists {
    my ($self, %spec) = @_;

    if ( !ref($spec{index}) ) {
        my ($status, undef) = $self->request(
            method => "HEAD",
            exists($spec{index}) ? ( index => $spec{index} ) : (),
            exists($spec{type})  ? ( type  => $spec{type}  ) : (),
        );

        return $status eq '200';
    }

    return undef;
}

sub create {
    my ($self, %spec) = @_;
    my $res = {};
    for my $index_name ( keys %{ $spec{index} } ) {
        my ($status, $body) = $self->request(
            index => $index_name,
            method => "PUT",
            body => $spec{index}{$index_name}
        );
        $res->{$index_name} = { status => $status, body => $body }
    }

    return $res;
}

sub delete {
    my ($self, %spec) = @_;
    my $res = {};
    my $index_name = $spec{index};
    my ($status, $body) = $self->request(
        index => $index_name,
        method => "DELETE"
    );
    $res->{$index_name} = { status => $status, body => $body };
    return $res;
}

sub search {
    my $self = shift;
    my %args = @_;
    my $search_type = delete $args{search_type};
    my ($status, $body) = $self->request(
        command => "_search",
        $search_type ? (
            uri_param => { search_type => $search_type }
        ) : (),
        body => \%args,
    );

    return {
        status => $status,
        body => $body,
    }
}


sub uri_search {
    my ($self, %args) = @_;
    my ($status, $body) = $self->request(
        command => "_search",
        uri_param => \%args,
    );
    return {
        status => $status,
        body => $body,
    }
}


1;
