#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Puncheur::Runner;

Puncheur::Runner->new('Riji', {
    port => 3650,
})->run;
