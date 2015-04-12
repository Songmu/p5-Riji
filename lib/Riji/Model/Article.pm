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
    default => sub {
        my $markupper = Riji->config->{markup} || 'Text::Markdown::Discount';
        my $obj = Text::Markup::Any->new($markupper);
        Text::Markdown::Discount::with_html5_tags() if $markupper eq 'Text::Markdown::Discount';
        $obj;
    },
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

        my $path = '/' . $self->file_path->relative(path($self->base_dir, $self->article_dir));
        my $ext = quotemeta $self->article_ext;
        $path =~ s/\.$ext$//;
        $path .= '.' . $self->page if $self->page;
        $path . '.html';
    },
);

has url => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $root = $self->site_url;
        $root =~ s!/+$!!;
        $root . $self->site_path;
    },
);
sub permalink { goto \&url }

#############
# Meta datas:
has title => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->header('title') // sub {
            my $prev;
            for my $line ( split /\r?\n/, $self->body ){
                if ( $line =~ /^#/ ){
                    $line =~ s/^[#\s]+//;
                    $line =~ s/[#\s]+$//;
                    return $line;
                }
                if ( $line =~ /^(?:(?:-+)|(?:=+))$/ ) {
                    return $prev if $prev && $prev =~ /[^\s]/;
                }
                $prev = $line;
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
    is  => 'ro',
    lazy => 1,
    default => sub {
        my $tags = shift->header('tags');
        return [] unless $tags;
        $tags = [split /[,\s]+/, $tags] unless ref $tags;
        $tags;
    },
);

has tags => (
    is      => 'ro',
    isa     => 'ArrayRef[Riji::Model::Tag]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [map {$self->blog->tag($_)} @{ $self->raw_tags }];
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
    my $content_raw = $self->content_raw;
       $content_raw =~ s/\A---\r?\n//ms;
    my ($header_raw, $body) = split /^---\n/ms, $content_raw, 2;

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
        path => Riji->template_dir,
        function => {
            uri_for   => sub { Riji->context->uri_for(@_) },
            config    => sub { Riji->config },
            Riji->get_functions,
        }
    );
}

1;
