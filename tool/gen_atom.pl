#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin::libs;

use Path::Tiny;
use Riji;

my $atom = Riji->new->model('Blog')->atom;
path('atom.xml')->spew_utf8($atom->feed->to_string);
