use strict;
use warnings;
use utf8;
use Test::More;

use File::Copy qw/move/;
use Path::Tiny;
use Scope::Guard qw/guard/;

use t::Util;

subtest 'riji setup' => sub {
    my $tmpd = riji_setup;

    for my $file (
        qw(riji.yml cpanfile .gitignore README.md .git/),
        (map { "article/$_" }    qw(archives.md index.md entry/sample.md)),
        (map { "share/tmpl/$_" } qw(base.tx default.tx entry.tx index.tx tag.tx)),
    ) {
        ok -e $file;
    }

    subtest 'riji publish' => sub {
        my $g = guard {
            path('blog')->remove_tree;
        };

        ok ! -d 'blog';
        riji 'publish';
        for my $file (map { "blog/$_" } qw(archives.html index.html entry/sample.html atom.xml) ) {
            ok -e $file;
        }
    };

    subtest 'add new entry' => sub {
        my $new_md = 'article/entry/new.md';
        my $g = guard {
            path('blog')->remove_tree;
        };
        path($new_md)->spew("# new!\n\nnew entry");
        git qw/add/, $new_md;
        git qw/commit -m new!/;
        my ($out, $err, $exit) = riji 'publish';
        for my $file (
            map { "blog/$_" } qw(archives.html index.html entry/sample.html entry/new.html atom.xml)
        ) {
            ok -e $file;
        }

        like path('blog/atom.xml')->slurp_utf8, qr/<content type="html">/;
    };

    subtest 'riji publish fails if in dirty entry_dir' => sub {
        my $hoge_md = 'article/entry/hoge.md';
        my $g = guard {
            unlink $hoge_md;
            path('blog')->remove_tree;
        };
        path($hoge_md)->spew('# hoge');
        my ($out, $err, $exit) = riji 'publish';
        cmp_ok $exit, '>', 0;
        like $err, qr/Unknown local files/;
        ok ! -d 'blog';
    };

    subtest 'riji publish success with --force even if in dirty index' => sub {
        my $hoge_md = 'article/entry/hoge.md';
        my $g = guard {
            unlink $hoge_md;
            path('blog')->remove_tree;
        };
        path($hoge_md)->spew('# hoge');
        my ($out, $err, $exit) = riji 'publish', '--force';
        is $exit, 0;
        ok -e 'blog/entry/hoge.html';
    };

    subtest "riji publish fails unless riji.yml" => sub {
        move 'riji.yml', 'riji.yml.bak';
        my $g = guard {
            move 'riji.yml.bak', 'riji.yml';
        };
        my ($out, $err, $exit) = riji 'publish';
        cmp_ok $exit, '>', 0;
        like $err, qr/config file: \[.*\] not found/
    };
};

done_testing;
