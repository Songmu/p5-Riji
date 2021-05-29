use strict;
use warnings;
use utf8;
use Test::More;
use Test::Output;
use Path::Tiny;

use FindBin;
use lib "$FindBin::Bin/..";
use t::Util;

use Riji::CLI::NewEntry;

subtest 'create dir unless article/entry' => sub {
    my $tmpd = riji_setup;
    my $article_dir = path("$tmpd/article");
    delete $ENV{EDITOR};

    stdout_like {
        Riji::CLI::NewEntry->run;
    } qr/\w is created. Edit it!/;

    my ($out, $err) = riji 'new-entry';
    like $out, qr/\w is created. Edit it!/;

    ok $article_dir->exists;
};

subtest 'riji new-entry fails unless riji.yml' => sub {
    my ($out, $err, $exit) = riji 'new-entry';
    cmp_ok $exit, '>', 0;
    like $err, qr/config file: \[.*\] not found/
};

done_testing;
