#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin::libs;

use Path::Tiny;

use Riji;
use Riji::Model::Atom;

my $atom = Riji::Model::Atom->new(
    base_dir => Riji->new->base_dir,
    fqdn     => 'riji.songmu.com',
);

path('atom.xml')->spew_utf8($atom->feed->to_string);
