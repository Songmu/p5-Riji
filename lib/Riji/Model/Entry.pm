package Riji::Model::Entry;
use 5.010;
use warnings;
use utf8;

use Time::Piece;
use URI::tag;

use Mouse;

extends 'Riji::Model::Article';

has repo_path => (
    is => 'ro',
    default => sub {
        my $self = shift;
        $self->file_path->relative($self->base_dir)
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


has template => (
    is  => 'ro',
    lazy => 1,
    default => sub {
        shift->header('template');
    },
);

no Mouse;

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
