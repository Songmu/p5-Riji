package t::Util;
use strict;
use warnings;
use utf8;

use File::pushd qw/tempd/;
use IPC::Cmd qw/run_forked/;
use Test::Mock::Guard qw/mock_guard/;

use Exporter 'import';
our @EXPORT = qw/cmd git riji riji_setup/;

sub cmd  {
    my %ret = %{ run_forked([@_]) };
    @ret{qw/stdout stderr exit_code/};
}
sub git  { cmd('git', @_) }

my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/riji');
sub riji {
    cmd($^X, "-I$lib", $bin, @_);
}

sub riji_setup {
    my $share = File::Spec->rel2abs('./share');
    my $tmpd = tempd();

    $ENV{GIT_AUTHOR_NAME}     = 'Songmu';
    $ENV{GIT_AUTHOR_EMAIL}    = 'songmu@example.com';
    $ENV{GIT_COMMITTER_NAME}  = 'Songmu';
    $ENV{GIT_COMMITTER_EMAIL} = 'songmu@example.com';
    {
        my $g = mock_guard Riji => {
            share_dir => $share,
        };
        require Riji::CLI::Setup;
        Riji::CLI::Setup->run;
    }
    $tmpd;
}

1;
