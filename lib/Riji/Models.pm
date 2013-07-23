package Riji::Models;
use strict;
use warnings;

use Object::Container -base;

register Blog => sub {
    my $self = shift;
    my $conf = $self->get('config');
    $self->ensure_class_loaded('Riji::Model::Blog')->new(
        base_dir => $self->get('base_dir'),
        fqdn     => $conf->{fqdn},
        author   => $conf->{author},
        title    => $conf->{title},
    );
};

1;
