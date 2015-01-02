use strict;
use warnings;
use utf8;
use Test::More;

use Riji::CLI::Publish;

my $sub = \&Riji::CLI::Publish::_expand_link;

is $sub->('dummy', 'http://www.example.com'), 'http://www.example.com';
is $sub->('dummy', '/www.ww'), '/www.ww';

is $sub->('/hoge/fuga', 'piyo'), '/hoge/piyo';
is $sub->('/hoge/fuga/', 'piyo'), '/hoge/fuga/piyo';

is $sub->('/hoge/fuga', '../piyo'), '/piyo';
is $sub->('/hoge/fuga/', '../piyo'), '/hoge/piyo';

is $sub->('/hoge/fuga', './piyo'), '/hoge/piyo';
is $sub->('/hoge/fuga/', './piyo'), '/hoge/fuga/piyo';

is $sub->('/hoge/fuga/', '../../piyo'), '/piyo';
is $sub->('/hoge/fuga/', '../.././piyo'), '/piyo';

done_testing;
