package Riji::Model::Entry;
use feature ':5.10';
use strict;
use warnings;

use HTTP::Date;
use Time::Piece;
use URI::tag;

use Mouse;

extends 'Riji::Model::Article';

has repo_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $repo_dir = $self->repo->run(qw/rev-parse --show-toplevel/);
        $self->file_path->relative($repo_dir)
    },
);

has file_history => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->repo->file_history($self->repo_path.'', {branch => $self->blog->branch});
    },
    handles => [qw/created_by last_modified_by/],
);

has site_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ext = quotemeta $self->article_ext;
        my $site_path = $self->file_path->basename;
        $site_path =~ s/\.$ext$//;
        "/entry/$site_path.html";
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
        $tag_uri->specific($self->blog->tag_uri_specific_prefix . join('-', grep {$_ ne ''} split(m{/}, $self->site_path)));

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
    lazy    => 1,
    default => sub {
        my $self = shift;

        my $updated_at   = $self->updated_at;
        my $published_at = $self->published_at;
        $published_at > $updated_at ? $published_at : $updated_at;
    },
);

has created_at => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        localtime($_[0]->file_history->created_at);
    },
);

has updated_at => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        localtime($_[0]->file_history->updated_at);
    },
);

has published_at => (
    is   => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        if (my $pubdate = $self->header('pubdate')) {
            return localtime(str2time($pubdate));
        }
        $self->created_at;
    }
);

no Mouse;

sub BUILD {
    my $self = shift;
    return unless $self->file_history;

    # surely assign them
    $self->last_modified_at;
    $self->created_at;
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
