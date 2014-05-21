use strict;
use warnings;
use utf8;
use Test::More;
use Test::Output;
use FindBin;
use Path::Tiny;
use Scope::Guard;
use Riji::CLI::NewEntry;

subtest 'create dir unless article/entry' => sub {
    my $article_dir = path('article');

    my $setup = do {
        delete $ENV{EDITOR};

        chdir $FindBin::Bin;
        fail "directory already exists: $article_dir" if $article_dir->exists;

        Scope::Guard->new(sub {
            $article_dir->remove_tree({safe => 0});
        });
    };

    stdout_like {
        Riji::CLI::NewEntry->run;
    } qr/\w is created. Edit it!/;
};

done_testing;
