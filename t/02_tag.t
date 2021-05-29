use strict;
use warnings;
use utf8;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
use t::Util;

use Path::Tiny;

subtest tag => sub {
    my $tmpd = riji_setup;

    subtest 'add new entry with tag' => sub {
        my $tag_md = 'article/entry/tag.md';
        path($tag_md)->spew_utf8("tags: Perl パール
---
# new!\n\nnew entry");

        my $tag2_md = 'article/entry/tag2.md';
        path($tag2_md)->spew_utf8("---
tags: Ruby, Python
---
# new!\n\nnew entry");

        git qw/add/, $tag_md, $tag2_md;
        git qw/commit -m new!/;
        my ($out, $err, $exit) = riji 'publish';
        for my $file (
            (map { "blog/$_" } qw(archives.html index.html entry/sample.html entry/tag.html entry/tag2.html atom.xml)),
            (map { "blog/tag/$_" } qw(Perl.html b32.4OBZDY4DXTRYHKY.html Ruby.html Python.html)),
        ) {
            ok -e $file, "$file found";
        }
    };
};

done_testing;
