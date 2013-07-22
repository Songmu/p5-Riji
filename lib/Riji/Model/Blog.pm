package Riji::Model::Blog;
use strict;
use warnings;
use utf8;

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
);

has atom => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Riji::Model::Atom->new(
            setting => $self->setting,
        );
    },
);

has entries => (
    is      => 'ro',
    isa     => 'ArrayRef[Riji::Model::Entry]',
    builder => '_build_entries',
);

no Mouse;

sub _build_entries {
    []
}

sub entry {
    my ($self, $file) = @_;

    Riji::Model::Entry->new(
        file    => $file,
        setting => $self->setting,
    );
}

1;
