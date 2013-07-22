package Riji::Model::Entry;
use 5.010;
use warnings;
use utf8;

use Path::Tiny;
use YAML::Tiny;
use Text::Markdown::Discount;
use Time::Piece;
use URI::tag;

use Mouse;

has file    => (
    is       => 'ro',
    required => 1,
);

has setting => (
    is       => 'ro',
    isa      => 'Riji::Model::BlogSetting',
    required => 1,
    handles  => [qw/base_dir fqdn author mkdn_dir url_root mkdn_path repo/],
);

has md => (
    is => 'ro',
    default => sub { Text::Markdown::Discount->new },
);

has file_path => (
    is => 'ro',
    default => sub {
        my $self = shift;
        path($self->base_dir, $self->mkdn_dir, $self->file);
    },
);

has content_raw => (
    is => 'ro',
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

has title => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->headers('title') // sub {
            for my $line ( split /\n/, $self->body ){
                if ( $line =~ /^#/ ){
                    $line =~ s/^[#\s]+//;
                    $line =~ s/[#\s]+$//;
                    return $line;
                }
            }
        }->() // 'unknown';
    },
);

has body_as_html => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->md->markdown($self->body);
    },
);

has file_history => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->repo->file_history($self->repo_path);
    },
    handles => [qw/created_by last_modified_by/],
);

has entry_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $entry_path = shift->file_path->basename;
        $entry_path =~ s/\.md$//;
        "entry/$entry_path.html";
    },
);

has url => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $root = $self->url_root;
        $root .= '/' unless $root =~ m!/$!;
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
        $tag_uri->date(localtime($self->file_history->last_modified_at)->strftime('%Y-%m-%d'));
        $tag_uri->specific(join('-',split(m{/},$self->entry_path)));

        $tag_uri;
    },
);

has is_draft => (
    is  => 'ro',
    lazy => 1,
    default => sub {
        shift->headers('draft');
    },
);

no Mouse;

sub BUILD {
    shift->_parse_content;
}

sub headers {
    my ($self, $key) = @_;
    if (defined $key){
        return $self->{headers}{$key};
    }
    else{
        return $self->{headers};
    }
}

sub last_modified_at {
    my $self = shift;
    $self->{last_modified_at} //= localtime($self->file_history->last_modified_at)->datetime;
}

sub created_at {
    my $self = shift;
    $self->{created_at} //= localtime($self->file_history->created_at)->datetime;
}

sub tags {...}

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
