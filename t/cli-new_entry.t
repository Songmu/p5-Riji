use strict;
use warnings;
use utf8;
use Test::More;
use Test::Output;
use FindBin;
use Path::Tiny;

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

done_testing;
