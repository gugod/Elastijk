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
    my ($status, $body) = Elastijk::request(\%args);
    return { status => $status, body => $body }
}

sub request_raw {
    my ($self, %args) = @_;
    $args{$_} ||= $self->{$_} for grep { exists $self->{$_} } qw(host port index type);
    my ($status, $body) = Elastijk::request_raw(\%args);
    return { status => $status, body => $body };
}

sub index {
    my ($self, %args) = @_;
    return $self->request(method => ( exists $args{id} ? "PUT" : "POST" ), %args);
}

sub get {
    my $self = shift;
    return $self->request(method => "GET", @_);
}

sub exists {
    my $self = shift;
    return $self->request(method => "HEAD", @_);
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
    my $self = shift;
    return $self->request(method => "DELETE", @_);
}

sub search {
    my $self = shift;
    return $self->request(command => "_search", method => "GET", @_);
}

sub bulk {
    my ($self, %args) = @_;
    $args{body} = join("", map { $Elastijk::JSON->encode($_)."\n" } @{$args{body}});
    my $res = $self->request_raw(method => "POST", command => "_bulk", %args);
    $res->{body} = $Elastijk::JSON->decode($res->{body}) if $res->{body};
    return $res;
}

1;
