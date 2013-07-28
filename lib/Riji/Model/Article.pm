package Riji::Model::Article;
use feature ':5.10';
use strict;
use warnings;

use Path::Tiny;
use YAML::Tiny ();
use Text::Markup::Any ();
use Text::Xslate;

use Mouse;

has file    => (
    is       => 'rw',
    required => 1,
);

has blog => (
    is       => 'ro',
    isa      => 'Riji::Model::Blog',
    required => 1,
    handles  => [qw/base_dir fqdn author article_dir site_url repo/],
);

has page => (
    is  => 'ro',
    isa => 'Int',
);

has markupper => (
    is      => 'ro',
    isa     => 'Text::Markup::Any',
    default => sub { Text::Markup::Any->new('Text::Markdown::Discount', {html5 => 1})},
    handles => [qw/markup/],
);

has article_ext => (is => 'ro', default => 'md');

has file_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        path($self->base_dir, $self->article_dir, $self->file);
    },
);

has content_raw => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        shift->file_path->slurp_utf8;
    },
);

has body => (is => 'rw');

has html_body => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $key = $self->isa('Riji::Model::Entry') ? 'entry' : 'article';
        my $body = $self->_pre_proccessor->render_string($self->body, {
            $key => $self,
            blog => $self->blog,
            page => $self->page,
        });
        $self->markup($body);
    },
);

has html_body_without_title => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $html = shift->html_body;
        $html =~ s!\A\s*<h[1-6].*?</h[1-6]>!!ms;
        $html;
    },
);

has site_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $path = '/' . $self->file_path->relative($self->base_dir);
        my $ext = quotemeta $self->article_ext;
        $path =~ s/\.$ext$//;
        $path .= '.' . $self->page if $self->page;
        $path . '.html';
    },
);

# Meta datas:
has title => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->header('title') // sub {
            for my $line ( split /\n/, $self->body ){
                if ( $line =~ /^#/ ){
                    $line =~ s/^[#\s]+//;
                    $line =~ s/[#\s]+$//;
                    return $line;
                }
            }
            my $ext = quotemeta $self->article_ext;
            my $title = $self->file_path->basename;
            $title =~ s/\.$ext$//;
            $title =~ s/-/ /g;
            $title;
        }->() // 'unknown';
    },
);

has is_draft => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        shift->header('draft');
    },
);

has raw_tags => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $tags = shift->header('tags');
        return [] unless $tags;
        $tags = [map {split /\s+/, $_} split /,\s*/, $tags] unless ref $tags;
        $tags;
    },
);

has template => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        shift->header('template');
    },
);

has paginate => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        shift->header('paginate');
    },
);

no Mouse;

sub BUILD {
    my $self = shift;

    my $ext = $self->article_ext;
    unless ($self->file =~ /\.\Q$ext\E$/) {
        $self->file($self->file . ".$ext");
    }
    return unless -f -r $self->file_path;
    $self->_parse_content;
}

sub header {
    my ($self, $key) = @_;
    if (defined $key){
        return $self->{headers}{$key};
    }
    else{
        return $self->{headers};
    }
}

sub _parse_content {
    my $self = shift;
    my ($header_raw, $body) = split /^---\n/ms, $self->content_raw, 2;

    my $headers = {};
    if (defined $body) {
        local $@;
        $headers = eval {
            YAML::Tiny::Load($header_raw);
        } || {};
        if ($@) {
            ($header_raw, $body) = ('', $self->content_raw);
        }
    }
    else {
        ($header_raw, $body) = ('', $header_raw);
    }

    $self->body($body);
    $self->{header_raw} = $header_raw;
    $self->{headers}    = $headers;
    $self;
}

sub _pre_proccessor {
    state $xslate = Text::Xslate->new(
        type => 'text',
        function => {
            c         => sub { Riji->context },
            uri_for   => sub { Riji->context->uri_for(@_) },
        }
    );
}

1;
