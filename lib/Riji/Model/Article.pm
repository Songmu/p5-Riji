package Riji::Model::Article;
use 5.010;
use warnings;

use Path::Tiny;
use YAML::Tiny;
use Text::Markup::Any ();

use Mouse;

has file    => (
    is       => 'ro',
    required => 1,
);

has blog => (
    is       => 'ro',
    isa      => 'Riji::Model::Blog',
    required => 1,
    handles  => [qw/base_dir fqdn author article_dir site_url repo/],
);

has markupper => (
    is      => 'ro',
    isa     => 'Text::Markup::Any',
    default => sub { Text::Markup::Any->new('Text::Markdown::Discount')},
    handles => [qw/markup/],
);

our $ARTICLE_EXT = 'md';
has article_ext => (is => 'ro', default => $ARTICLE_EXT);

has file_path => (
    is => 'ro',
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

has body_as_html => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->markup($self->body);
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
    is  => 'ro',
    lazy => 1,
    default => sub {
        shift->header('draft');
    },
);

has tags => (
    is  => 'ro',
    lazy => 1,
    default => sub {
        my $tags = shift->header('tags');
        return [] unless $tags;
        $tags = [split /,\s*/, $tags] unless ref $tags;
        $tags;
    },
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $args = $class->$orig(@_);

    $args->{file} .= ".$ARTICLE_EXT" unless $args->{file} =~ /\.\Q$ARTICLE_EXT\E$/;
    $args;
};

no Mouse;

sub BUILD {
    my $self = shift;
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

1;
