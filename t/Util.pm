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
    my %ret = %{ run_forked(join ' ', @_) };
    @ret{qw/stdout stderr exit_code/};
}
sub git  { cmd('git', @_) }

my $lib = File::Spec->rel2abs('lib');
my $bin = File::Spec->rel2abs('script/riji');
sub riji {
    my @args = @_;
    if ($ENV{RIJI_TEST_INTERNAL}) {
        # for calculating coverage. mainly in travis.
        require Capture::Tiny;
        require Class::Unload;
        require String::CamelCase;
        require Module::Load;

        if ($INC{'Riji.pm'}) {
            Class::Unload->unload('Riji');
        }
        require Riji;
        if ($INC{'Riji/Models.pm'} && Riji::Models->instance->registered_classes->{Blog}) {
            Riji::Models->unregister('Blog');
            Riji::Models::register_blog();
        }

        my $cmd = shift @args;
        $cmd =~ s/-/_/g;
        $cmd = String::CamelCase::camelize($cmd);
        my $pkg = "Riji::CLI::$cmd";
        Module::Load::load($pkg);
        Capture::Tiny::capture(sub{
            eval { $pkg->run(@args) };
            if ($@) {
                warn $@;
                return 255;
            }
            0;
        });
    }
    else {
        cmd($^X, "-I$lib", $bin, @args);
    }
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
