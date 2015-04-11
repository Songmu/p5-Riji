use strict;
use warnings;
use utf8;
use Test::More;
use Path::Tiny;
use Scope::Guard qw/guard/;

use t::Util;

subtest 'riji setup' => sub {
    my $tmpd = riji_setup;

    my $functionspl = 'share/functions.pl';
    path($functionspl)->spew(<<'...');
sub hoge {
    'RIJIHOGE'
}

sub fuga {
    my $post = shift;
    'RIJIFUGA' . $post;
}
...
    git qw/add/, $functionspl;
    git qw/commit -m/, "add functions.pl";

    subtest 'functions in entry' => sub {
        my $new_md = 'article/entry/new.md';
        my $g = guard {
            path('blog')->remove_tree;
        };
        path($new_md)->spew("# new!\n\nnew entry
        <: hoge() :>");
        git qw/add/, $new_md;
        git qw/commit -m new!/;
        my ($out, $err, $exit) = riji 'publish';

        like path('blog/entry/new.html')->slurp_utf8, qr/RIJIHOGE/;
    };


    subtest 'functions in template' => sub {
        my $new_md = 'article/entry/new2.md';
        my $g = guard {
            path('blog')->remove_tree;
        };
        path($new_md)->spew("template: fuga
---
# new!\n\nnew entry");
        my $tmpl = 'share/tmpl/fuga.tx';
        path($tmpl)->spew('<: fuga(15) :>');

        git qw/add/, $new_md, $tmpl;
        git qw/commit -m new!/;
        my ($out, $err, $exit) = riji 'publish';

        like path('blog/entry/new2.html')->slurp_utf8, qr/RIJIFUGA15/;
    };
};

done_testing;
