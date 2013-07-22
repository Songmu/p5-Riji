package Riji::Model::BlogSetting;
use strict;
use warnings;
use utf8;

use Git::Repository 'FileHistory';
use Path::Tiny 'path';

use Mouse;

has base_dir => (is => 'ro', required => 1);
has fqdn     => (is => 'ro', required => 1);
has author   => (is => 'ro', required => 1);
has title    => (is => 'ro', required => 1);
has mkdn_dir => (is => 'ro', required => 1);
has url_root => (
    is      => 'ro',
    default => sub { "http://@{[shift->fqdn]}/"},
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

no Mouse;

1;
