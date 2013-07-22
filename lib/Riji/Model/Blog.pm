package Riji::Model::Blog;
use strict;
use warnings;
use utf8;

use List::UtilsBy qw/rev_sort_by/;

use Riji::Model::BlogSetting;
use Riji::Model::Atom;

use Mouse;

has base_dir => (
    is       => 'ro',
    required => 1,
);

has fqdn => (
    is       => 'ro',
    required => 1,
);

has author => (
    is      => 'ro',
    default => 'Masayuki Matsuki',
);

has title => (
    is      => 'ro',
    default => "Songmu's Riji",
);

has mkdn_dir => (
    is => 'ro',
    default => 'docs/entry',
);

has setting => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Riji::Model::BlogSetting->new(
            base_dir => $self->base_dir,
            fqdn     => $self->fqdn,
            author   => $self->author,
            title    => $self->title,
            mkdn_dir => $self->mkdn_dir,
        );
    },
    handles => [qw/mkdn_path repo/],
);

has atom => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Riji::Model::Atom->new(
            setting => $self->setting,
            entries => $self->entries,
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

    Riji::Model::Entry->new(
        file    => $file,
        setting => $self->setting,
    );
}

1;
