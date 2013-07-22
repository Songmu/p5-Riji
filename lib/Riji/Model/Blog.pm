package Riji::Model::Blog;
use strict;
use warnings;
use utf8;

use Riji::Model::BlogSetting;
use Riji::Model::Atom;

sub new {
    my ($class, %args) = @_;
    bless {%args}, $class;
}

sub base_dir { shift->{base_dir} }
sub fqdn     { shift->{fqdn}   }
sub author   { 'Masayuki Matsuki' }
sub title    { "Songmu's Riji"    }
sub mkdn_dir { 'docs/entry'       }

sub setting {
    my $self = shift;

    $self->{setting} //= Riji::Model::BlogSetting->new(
        base_dir => $self->base_dir,
        fqdn     => $self->fqdn,
        author   => $self->author,
        title    => $self->title,
        mkdn_dir => $self->mkdn_dir,
    );
}

sub atom {
    my $self = shift;

    $self->{atom} //= Riji::Model::Atom->new(
        setting => $self->setting,
    );
}

1;
