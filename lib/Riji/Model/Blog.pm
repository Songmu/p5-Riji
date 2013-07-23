package Riji::Model::Blog;
use strict;
use warnings;
use utf8;

use Git::Repository 'FileHistory';
use List::UtilsBy qw/rev_sort_by/;
use Path::Tiny 'path';

use Riji::Model::BlogSetting;
use Riji::Model::Atom;

use Mouse;

has base_dir => (is => 'ro', required => 1);
has fqdn     => (is => 'ro', required => 1);
has author   => (is => 'ro', required => 1);
has title    => (is => 'ro', required => 1);

has mkdn_dir => (
    is => 'ro',
    default => 'docs/entry',
);

has url_root => (
    is      => 'ro',
    default => sub { "http://@{[shift->fqdn]}"},
);

has mkdn_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        path($self->base_dir, $self->mkdn_dir);
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
            grep        { !$_->is_draft }
            map         { $self->entry($_->basename) }
            grep        { -f -r $_ && /\.md$/ }
            $self->mkdn_path->children
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
