package Riji::CLI::Setup;
use 5.010;
use warnings;

use Cwd qw/getcwd/;
use File::Copy qw/copy/;
use File::Copy::Recursive qw/dircopy/;
use File::Spec;
use File::Which qw/which/;
use Path::Tiny;

use Riji;

sub run {
    my ($class, @argv) = @_;

    my $force = grep {$_ eq '--force'} @argv;

    my $share_dir = Riji->share_dir;
    my $setup_dir = getcwd;

    if (!$force && path($setup_dir)->children) {
        die "you must run `riji setup` in empty directory or `riji setup --force`.\n";
    }
    my $tmpl_dir = File::Spec->catdir($share_dir, 'tmpl');

    dircopy(
        File::Spec->catdir($share_dir, 'tmpl'),
        File::Spec->catdir($setup_dir, 'share', 'tmpl')
    );
    dircopy(
        File::Spec->catdir($share_dir, 'article'),
        File::Spec->catdir($setup_dir, 'article')
    );
    copy(
        File::Spec->catfile($share_dir, 'riji.yml'),
        $setup_dir
    );
    copy(
        File::Spec->catfile($share_dir, 'README.md'),
        $setup_dir
    );

    my $git = which 'git' or die "git not found.\n";
    system($git, qw!init!);
    system($git, qw!add .!);
    system($git, qw/commit -m/, "initial blog commit");
}

1;
