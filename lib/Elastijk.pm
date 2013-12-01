package Elastijk;
use strict;
use warnings;
our $VERSION = "0.01";

use JSON ();
use URI::Escape qw(uri_escape);
use Hijk;

our $JSON = JSON->new->utf8;

sub _build_hijk_request_args {
    my $args = $_[0];
    my ($path, $qs, $uri_param);
    $path = "/". join("/", grep { defined } @{$args}{qw(index type command)});
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
    $res_body = $res_body ? $JSON->decode($res_body) : undef;
    return $status, $res_body;
}

sub request_raw {
    my $args = _build_hijk_request_args($_[0]);
    my $res = Hijk::request($args);
    return $res->{status}, $res->{body};
}


1;

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

Elastijk is a ElasticSearch client library. It uses L<Hijk>, a HTTP client that
implements a tiny subset of HTTP/1.1 that makes it just enough to talk to
ElasticSearch via HTTP.

=head1 FUNCTIONS

=head2 Elastijk::request( $args :HashRef ) : ($status :Int, $response :HashRef)

Making a request to the ElasticSearch server specified in C<$args>. It returns 2
values. C<$status> is the HTTP status code of the response, and the C<$response>
decoded as HashRef. ElasticSearch API always respond a single HashRef as JSON
text, this might or might not be changed in the future, if it is changed then
this function will be adjusted accordingly.

=head2 Elastijk::request_raw( $args :HashRef ) : ($status :Int, $response :Str)

Making a request to the ElasticSearch server specified in C<$args>. The main
difference between this function and C<Elastijk::request> is that
C<$args->{body}> s expected to be a String scalar, rather then a HashRef. And
the $response is not decoded from JSON. This function can be used if users wish
to use their own JSON parser to parse response, or if they wish to delay the
parsing to be done latter in some bulk-processing pipeline.

=head1 AUTHORS

=over 4

=item Kang-min Liu <gugod@gugod.org>

=item Borislav Nikolov <jack@sofialondonmoskva.com>

=back

=head1 COPYRIGHT

Copyright (c) 2013 Kang-min Liu C<< <gugod@gugod.org> >>.

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
