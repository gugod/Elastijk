package Elastijk;
use strict;
use warnings;
our $VERSION = "0.05";

use JSON ();
use URI::Escape qw(uri_escape);
use Hijk;

our $JSON = JSON->new->utf8;

sub _build_hijk_request_args {
    my $args = $_[0];
    my ($path, $qs, $uri_param);
    $path = "/". join("/", grep { defined } @{$args}{qw(index type id command)});
    if ($args->{uri_param}) {
        $qs =  join('&', map { uri_escape($_) . "=" . uri_escape($args->{uri_param}{$_}) } keys %{$args->{uri_param}});
    }

    return {
        method => $args->{method} || 'GET',
        host   => $args->{host}   || 'localhost',
        port   => $args->{port}   || '9200',
        !$path ?() :(
            path   => $path
        ),
        !$qs ?() :(
            query_string => $qs
        ),
        !$args->{body} ?() :(
            body => (ref($args->{body}) ? $JSON->encode($args->{body}) : $args->{body})
        ),
    }
}

sub request {
    my $arg = $_[0];
    if ($arg->{body}) {
        $arg = {%{$_[0]}};
        $arg->{body} = $JSON->encode( $arg->{body} );
    }
    my ($status, $res_body) = request_raw($arg);
    $res_body = $res_body ? eval { $JSON->decode($res_body) } : undef;
    return $status, $res_body;
}

sub request_raw {
    my $args = _build_hijk_request_args($_[0]);
    my $res = Hijk::request($args);
    return $res->{status}, $res->{body};
}

sub new {
    shift;
    require Elastijk::oo;
    return Elastijk::oo->new(@_);
}

1;

__END__

=encoding utf-8

=head1 NAME

Elastijk - A specialized ElasticSearch client.

=head1 SYNOPSIS

    use Elastijk;

    my ($status, $response) = Elastijk::request({
        host => "localhost",
        port => "9200",
        method => "GET",

        index => "blog",
        type => "article",
        command => "_search",

        uri_param => { search_type => "dfs_query_then_fetch" }
        body => {
            query => { match => { "body" => "cpan" } }
        }
    });

    if ($status eq "200") {
        for my $hit (@{ $response->{hits}{hits} }) {
            say $hit->{url};
        }
    }

=head1 DESCRIPTION

Elastijk isn a ElasticSearch client library. It uses L<Hijk>, a HTTP client that
implements a tiny subset of HTTP/1.1 just enough to talk to ElasticSearch via
HTTP.

Elastijk provided low-level functions that are almost identical as using HTTP
client, and an object-oriented sugar layer to make it a little bit easier to
use. The following documentation describe the low-level function first.

=head1 FUNCTIONS

=head2 Elastijk::request( $args :HashRef ) : ($status :Int, $response :HashRef)

Making a request to the ElasticSearch server specified in C<$args>. It returns 2
values. C<$status> is the HTTP status code of the response, and the C<$response>
decoded as HashRef. ElasticSearch API always respond a single HashRef as JSON
text, this might or might not be changed in the future, if it is changed then
this function will be adjusted accordingly.

The C<$args> is a HashRef takes contains the following key-value pairs:

    host  => Str
    port  => Str
    index => Str
    type  => Str
    id    => Str
    command => Str
    uri_param => HashRef
    body  => HashRef | ArrayRef | Str
    method => "GET" | "POST" | "HEAD" | "PUT" | "DELETE"

The 4 values of C<index>, C<type>, C<id>, C<command> are used to form the URI
path following ElasticSearch's routing convention:

    /${index}/${type}/${id}/${command}

All these path parts are optional, when that is the case, Elstaijk properly
remove C</> in between to form the URL that makes sense, for example:

    /${index}/${type}/${id}
    /${index}/${command}

The value of C<uri_param> is used to form the query_string part in the URI, some
common ones for ElasticSearch are C<q>, C<search_type>, and C<timeout>.  But the
accepted list is different for different commands.

The value of C<method> corresponds to HTTP verbs, and is hard-coded to match
ElasticSearch API. Users generally do not need to provide this value, unless you
are calling C<request> directly, in which case, the default value is 'GET'.

For all cases, Elastijk simply bypass the value it recieve to the server without
doing any parameter validation. If that generates some errors, it'll be on
server side.

=head2 Elastijk::request_raw( $args :HashRef ) : ($status :Int, $response :Str)

Making a request to the ElasticSearch server specified in C<$args>. The main
difference between this function and C<Elastijk::request> is that
C<$args->{body}> s expected to be a String scalar, rather then a HashRef. And
the $response is not decoded from JSON. This function can be used if users wish
to use their own JSON parser to parse response, or if they wish to delay the
parsing to be done latter in some bulk-processing pipeline.

=head1 OBJECT

=head2 PROPERTIES

An Elastijk object is constructed like this:

    my $es = Elastijk->new(
        host => "es1.example.com",
        port => "9200"
    );

Under the hood, it is only a blessed hash, while all key-value pairs in the hash
are the properties. Users could break the pacaking and modify those values, but
it is fine. All key-value pairs are shallow-copied from `new` method.

Here's a full list of key-value pairs that are consumed:

    host  => Str "localhost"
    port  => Str "9200"
    index => Str (optional)
    type  => Str (optional)

The values for C<index> and C<type> act like a "default" value and they are only
used in methods that could use them. Which is handy to save some extra typing.
Given objects constructed with different default of C<index> attribute:

    $es0 = Elastijk->new();
    $es1 = Elastijk->new( index => "foo" );

... calling the same C<search> method with the same arugments will generate
different request:

    my @args = (uri_param => { q => "nihao" });
    $es0->search( @args  ); # GET /_search?q=nihao
    $es1->search( @args  ); # GET /foo/_search?q=nihao

This behaviour is consistent for all methods.

=head1 METHODS

All methods takes the same key-value pair HashRef as C<Elastijk::request> function,
and returns 2 values that are HTTP status code, and the body hashref.

Many of of methods are named after an server command. For eaxmple, the command
C<_search> corresponds to method C<search>, the command C<_bulk> corresponds to
method C<bulk>.

Elastijk does as little data transformation as possible to keep it a
stupid, thin client.

All methods return 2 values that are HTTP status code, and the body hashref:

    my ($status, $res) = $es->search(...)
    if (substr($status,0,1) eq '2') { # 2xx = successful
        ...
    }

The status code is used for error-checking purposes. ElastiSearch should respond
with status 4XX when the relevant thing is missing, and 5XX when there are some
sort of errors. To check if a request is successful, test if it is 200 or 201.

Due to the fact the value of a lists is the last value of element, it is a
little bit shorter if status check could be ignored:

    my $res = $es->search(...);
    for (@{ $res->{hits}hits} }) {
        ...
    }

C<count> and C<exists> method modified C<$res> to be a scalar (instead of
HashRef) to allow these intuitive use cases:

    if ($es->exists(...)) { ... }
    if ($es->count(...) > 10) { ... }

... the original response body are discarded.

=head2 request( ... )

This is a low-level method that just bypass things, but it is useful when, say,
newer ElasticSearch versoin introduce a new command, and there are no
corresponding method in the Client yet. The only difference between using this
method and calling C<Elasijk::request> directly, is that the values of
C<host>,C<port>,C<index>, and <type> ind the object context are consumed.

=head2 head(...), get(...), put(...), post(...), delete(...)

Shorthands for the HTTP verbs. All these are just direct delegate to C<request>
method.

=head2 search( body => {...}, uri_param => {...} )

This method invokes L<the search api|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-search.html>.

The arguments are key-value pairs from the API documents.

=head2 count( body => {...}, uri_param => {...} )

This method corresponds to L<the search count api|http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-count.html>

=head2 exists( index => Str, type => Str, id => Str )

Check if the given thing exists. Which can be a document, a type, and an index.
Due to the nature of their dependency, here's the combination you would need
to check the existence of different things:

    document: index => "foo", type => "bar", id => "beer"
    type:     index => "foo", type => "bar"
    index:    index => "foo"

See also L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-exists.html> ,
L<http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/indices-types-exists.html#indices-types-exists> , and L<http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/doc-exists.html>

=head1 AUTHORS

=over 4

=item Kang-min Liu <gugod@gugod.org>

=item Borislav Nikolov <jack@sofialondonmoskva.com>

=back

=head1 COPYRIGHT

Copyright (c) 2013,2014 Kang-min Liu C<< <gugod@gugod.org> >>.

=head1 LICENCE

The MIT License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
