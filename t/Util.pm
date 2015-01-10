package t::Util;
use strict;
use warnings;
use utf8;

use File::pushd qw/tempd/;
use IPC::Cmd qw/run_forked/;
use Exporter 'import';
our @EXPORT = qw/cmd git riji riji_setup/;

sub cmd  {
    my %ret = %{ run_forked([@_]) };
    @ret{qw/stdout stderr exit_code/};
}
sub git  { cmd('git', @_) }
sub riji { cmd('riji', @_) }

sub riji_setup {
    my $tmpd = tempd();
    riji 'setup';
    $tmpd;
}

1;
