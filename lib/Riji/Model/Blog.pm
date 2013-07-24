package Riji::Model::Blog;
use strict;
use warnings;
use utf8;

use Git::Repository 'FileHistory';
use List::UtilsBy qw/rev_sort_by/;
use Path::Tiny 'path';

use Riji::Model::Atom;
use Riji::Model::Entry;

use Mouse;

has base_dir => (is => 'ro', required => 1);
has author   => (is => 'ro', required => 1);
has title    => (is => 'ro', required => 1);
has site_url => (
    is       => 'ro',
    isa      => 'URI',
    required => 1
);

has fqdn => (
    is      => 'ro',
    lazy    => 1,
    default => sub {shift->site_url->host},
);

has tag_uri_specific_prefix => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $pref = shift->site_url->path;
        $pref =~ s!/$!!;
        $pref =~ s!^/!!;
        $pref =~ s!/!-!g;
        $pref .= ':' if $pref;
        $pref;
    },
);

has article_dir => (
    is => 'ro',
    default => 'article',
);

has article_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        path($self->base_dir, $self->article_dir);
    },
);

has repo => (
    is   => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Git::Repository->new(work_tree => $self->base_dir);
    },
);

has git_branch => (
    is      => 'ro',
    default => 'master',
);

has atom => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Riji::Model::Atom->new(
            blog => $self
        );
    },
);

has entries => (
    is      => 'ro',
    isa     => 'ArrayRef[Riji::Model::Entry]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [
            rev_sort_by { $_->created_at }
            grep        { $_ && !$_->is_draft }
            map         { $self->entry($_->basename) }
            grep        { -f -r $_ && /\.md$/ }
            $self->article_path->children
        ]
    },
);

no Mouse;

sub entry {
    my ($self, $file) = @_;

    my $entry = Riji::Model::Entry->new(
        file => $file,
        blog => $self,
    );
    return () unless -f -r $entry->file_path;

    $entry;
}

1;
