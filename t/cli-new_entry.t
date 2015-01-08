use strict;
use warnings;
use utf8;
use Test::More;
use Test::Output;
use FindBin;
use Path::Tiny;
use File::pushd;

use Riji::CLI::NewEntry;

subtest 'create dir unless article/entry' => sub {
    my $tmpd = tempd();
    my $article_dir = path("$tmpd/article");
    delete $ENV{EDITOR};

    stdout_like {
        Riji::CLI::NewEntry->run;
    } qr/\w is created. Edit it!/;

    ok $article_dir->exists;
};

done_testing;
