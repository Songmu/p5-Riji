package Riji::Models;
use strict;
use warnings;

use URI;

use Object::Container -base;

register Blog => sub {
    my $self = shift;
    my $conf = $self->get('config');
    my $site_url = sub {
        return URI->new($conf->{site_url}) if $conf->{site_url};

        require Riji;
        Riji->context ? Riji->context->req->base : URI->new('http://unknown.example.com/');
    }->();

    $self->ensure_class_loaded('Riji::Model::Blog')->new(
        base_dir => $self->get('base_dir'),
        site_url => $site_url,
        author   => $conf->{author},
        title    => $conf->{title},
        ($conf->{branch} ? (branch => $conf->{branch}) : ()),
    );
};

no Object::Container;
1;
