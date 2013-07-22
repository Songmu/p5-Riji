package Riji::Models;
use strict;
use warnings;

use Object::Container -base;

register Blog => sub {
    my $self = shift;
    $self->ensure_class_loaded('Riji::Model::Blog')->new(
        base_dir => $self->get('base_dir'),
        fqdn     => 'riji.songmu.jp',
    );
};

1;
