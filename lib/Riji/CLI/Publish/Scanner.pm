package Riji::CLI::Publish::Scanner;
use strict;
use warnings;

use Plack::Util ();
use Carp;
use HTTP::Date qw( time2str );
use parent 'Wallflower';

for my $attr (qw( mount scheme server_name )) {
    no strict 'refs';
    *$attr = sub { $_[0]{$attr} };
}

sub _application {
    my $self = shift;

    my $app = $self->application;
    return $app unless defined $self->mount;

    require Plack::App::URLMap;
    my $urlmap = Plack::App::URLMap->new;
    $urlmap->mount($self->mount => $self->application);
    $urlmap->to_app;
}

# most of code copied from Wallflower
sub get {
    my ( $self, $uri ) = @_;
    $uri = URI->new($uri) if !ref $uri;

    # absolute paths have the empty string as their first path_segment
    croak "$uri is not an absolute URI"
        if $uri->path && length +( $uri->path_segments )[0];

    # setup the environment
    my $env = {

        # current environment
        %ENV,

        # overridable defaults
        'psgi.errors' => \*STDERR,

        # current instance defaults
        %{ $self->env },
        ('psgi.url_scheme' => $self->scheme )x!! $self->scheme,

        # request-related environment variables
        REQUEST_METHOD => 'GET',

        # Plack::App::URLMap deal with SCRIPT_NAME and PATH_INFO with mounts
        SCRIPT_NAME     => '',
        PATH_INFO       => $uri->path,
        REQUEST_URI     => $uri->path,
        QUERY_STRING    => '',
        SERVER_NAME     => $self->server_name || 'localhost',
        SERVER_PORT     => ($self->scheme || '') eq 'https' ? 443 : 80,
        SERVER_PROTOCOL => "HTTP/1.0",

        # wallflower defaults
        'psgi.streaming' => '',
    };

    # add If-Modified-Since headers if the target file exists
    my $target = $self->target($uri);
    $env->{HTTP_IF_MODIFIED_SINCE} = time2str( ( stat _ )[9] ) if -e $target;

    # fixup URI (needed to resolve relative URLs in retrieved documents)
    $uri->scheme($self->scheme || 'http') if !$uri->scheme;
    $uri->host( $env->{SERVER_NAME} ) if !$uri->host;

    # get the content
    my ( $status, $headers, $file, $content ) = ( 500, [], '', '' );
    my $res = Plack::Util::run_app( $self->_application, $env );

    if ( ref $res eq 'ARRAY' ) {
        ( $status, $headers, $content ) = @$res;
    }
    elsif ( ref $res eq 'CODE' ) {
        croak "Delayed response and streaming not supported yet";
    }
    else { croak "Unknown response from application: $res"; }

    # save the content to a file
    if ( $status eq '200' ) {

        # get a file to save the content in
        my $dir = ( $file = $target )->dir;
        $dir->mkpath if !-e $dir;
        open my $fh, '>', $file or croak "Can't open $file for writing: $!";

        # copy content to the file
        if ( ref $content eq 'ARRAY' ) {
            print $fh @$content;
        }
        elsif ( ref $content eq 'GLOB' ) {
            local $/ = \8192;
            print {$fh} $_ while <$content>;
            close $content;
        }
        elsif ( eval { $content->can('getline') } ) {
            local $/ = \8192;
            while ( defined( my $line = $content->getline ) ) {
                print {$fh} $line;
            }
            $content->close;
        }
        else {
            croak "Don't know how to handle body: $content";
        }

        # finish
        close $fh;
    }

    return [ $status, $headers, $file ];
}

1;
