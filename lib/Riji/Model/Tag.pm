package Riji::Model::Tag;
use 5.010;
use strict;
use warnings;

use Mouse;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has entries => (
    is => 'rw',
    isa => 'ArrayRef[Riji::Model::Entry]',
    lazy    => 1,
    default => sub { [] },
);

has count => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        scalar @{ shift->entries };
    },
);

has site_path => (
    is      => 'ro',
    default => sub { '/tag/' . shift->name . '.html' },
);

no Mouse;

1;
