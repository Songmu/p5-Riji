#!/usr/bin/env perl
use 5.010;
use warnings;
use utf8;
use Encode;
use FindBin::libs;

use Path::Tiny;
use Riji;

# uri_forが呼べなくてpreprocessできない問題ある
my $atom = Riji->new->model('Blog')->atom;
say encode_utf8 $atom->feed->to_string;
