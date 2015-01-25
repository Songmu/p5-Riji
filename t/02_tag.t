use strict;
use warnings;
use utf8;
use Test::More;

use t::Util;
use Path::Tiny;

subtest tag => sub {
    my $tmpd = riji_setup;

    subtest 'add new entry with tag' => sub {
        my $tag_md = 'article/entry/tag.md';
        path($tag_md)->spew_utf8("tags: Perl パール
---
# new!\n\nnew entry");
        git qw/add/, $tag_md;
        git qw/commit -m new!/;
        my ($out, $err, $exit) = riji 'publish';
        for my $file (
            (map { "blog/$_" } qw(archives.html index.html entry/sample.html entry/tag.html atom.xml)),
            (map { "blog/tag/$_" } qw(Perl.html b32.4OBZDY4DXTRYHKY.html)),
        ) {
            ok -e $file;
        }
    };
};

done_testing;
