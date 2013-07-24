package Riji::Model::Entry;
use 5.010;
use warnings;
use utf8;

use Path::Tiny;
use YAML::Tiny;
use Text::Markup::Any ();
use Time::Piece;
use URI::tag;

use Mouse;

has file    => (
    is       => 'ro',
    required => 1,
);

has blog => (
    is       => 'ro',
    isa      => 'Riji::Model::Blog',
    required => 1,
    handles  => [qw/base_dir fqdn author article_dir site_url article_path repo/],
);

has markupper => (
    is      => 'ro',
    isa     => 'Text::Markup::Any',
    default => sub { Text::Markup::Any->new('Text::Markdown::Discount')},
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

has repo_path => (
    is => 'ro',
    default => sub {
        my $self = shift;
        $self->file_path->relative($self->base_dir)
    },
);

has body => (is => 'rw');

has body_as_html => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->markupper->markup($self->body);
    },
);

has file_history => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        $self->repo->file_history($self->repo_path, {branch => $self->blog->git_branch});
    },
    handles => [qw/created_by last_modified_by/],
);

has entry_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ext = quotemeta $self->article_ext;
        my $entry_path = $self->file_path->basename;
        $entry_path =~ s/\.$ext$//;
        "/entry/$entry_path.html";
    },
);

has url => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $root = $self->site_url;
        $root =~ s!/+$!!;
        $root . $self->entry_path;
    },
);

has tag_uri => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $tag_uri = URI->new('tag:');
        $tag_uri->authority($self->fqdn);
        $tag_uri->date($self->created_at->strftime('%Y-%m-%d'));
        $tag_uri->specific($self->blog->tag_uri_specific_prefix . join('-', grep {$_ ne ''} split(m{/}, $self->entry_path)));

        $tag_uri;
    },
);

has next => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ($prev, $next) = $self->_search_prev_and_next;
        $self->prev($prev);
        $next;
    },
);

has prev => (
    is => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my ($prev, $next) = $self->_search_prev_and_next;
        $self->next($next);
        $prev;
    },
);

has last_modified_at => (
    is      => 'ro',
    default => sub {
        localtime($_[0]->file_history->last_modified_at);
    },
);

has created_at => (
    is      => 'ro',
    default => sub {
        localtime($_[0]->file_history->created_at);
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
            my $title = $self->file;
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

has template => (
    is  => 'ro',
    lazy => 1,
    default => sub {
        shift->header('template');
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

sub _search_prev_and_next {
    my $self = shift;
    my ($prev, $next);

    my $found;
    my @entries = @{ $self->blog->entries };
    while (my $entry = shift @entries) {
        if ($entry->file eq $self->file) {
            $prev = shift @entries;
            $found++; last;
        }
        $next = $entry;
    }
    return () unless $found;
    ($prev, $next);
}

1;
