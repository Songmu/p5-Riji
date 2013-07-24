package Riji::Model::Blog;
use strict;
use warnings;
use utf8;

use File::Spec;
use Git::Repository 'FileHistory';
use List::UtilsBy qw/rev_sort_by rev_nsort_by/;
use Path::Tiny 'path';

use Riji::Model::Atom;
use Riji::Model::Entry;
use Riji::Model::Tag;

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

has entry_dir => (
    is => 'ro',
    default => 'article/entry',
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
            rev_sort_by { $_->created_at->datetime . $_->file }
            grep        { $_ && !$_->is_draft }
            map         { $self->entry($_->basename) }
            grep        { -f -r }
            $self->article_path->child('entry')->children
        ]
    },
);

has tag_map => (
    is      => 'ro',
    isa     => 'HashRef[Riji::Model::Tag]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my %map;
        for my $entry (@{ $self->entries }) {
            for my $tag (@{ $entry->raw_tags }) {
                $map{$tag} ||= Riji::Model::Tag->new(name => $tag);
                push @{$map{$tag}->entries}, $entry;
            }
        }
        \%map;
    },
);

has tags => (
    is      => 'ro',
    isa     => 'ArrayRef[Riji::Model::Tag]',
    lazy    => 1,
    default => sub {
        [rev_nsort_by {$_->count} values %{ shift->tag_map }]
    },
);

no Mouse;

sub entry {
    my ($self, $file) = @_;

    my $entry = Riji::Model::Entry->new(
        file => File::Spec->catfile('entry', $file),
        blog => $self,
    );
    return () unless -f -r $entry->file_path;

    $entry;
}

sub article {
    my ($self, $file, $opt) = @_;

    my $article = Riji::Model::Article->new(
        file => $file,
        blog => $self,
        %$opt,
    );
    return () unless -f -r $article->file_path;

    $article;
}

sub tag {
    my ($self, $tag) = @_;
    $self->tag_map->{$tag};
}

1;
