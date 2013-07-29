package Riji::CLI::Setup;
use feature ':5.10';
use strict;
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

    my $recurse644; $recurse644 = sub {
        my $dir = shift;
        for my $file ($dir->children) {
            if (-d $file) {
                $recurse644->($file); next;
            }
            chmod 0644, $file;
        }
    };

    my $target_dir = File::Spec->catdir($setup_dir, 'share', 'tmpl');
    dircopy(File::Spec->catdir($share_dir, 'tmpl'), $target_dir);
    $recurse644->(path($target_dir));

    $target_dir = File::Spec->catdir($setup_dir, 'article');
    dircopy(File::Spec->catdir($share_dir, 'article'), $target_dir);
    $recurse644->(path($target_dir));

    copy(File::Spec->catfile($share_dir, 'riji.yml'), $setup_dir);
    copy(File::Spec->catfile($share_dir, 'README.md'), $setup_dir);

    my $git = which 'git' or die "git not found.\n";

    unless (-e path($setup_dir)->child('.git')) {
        system($git, qw!init!);
    }
    system($git, qw!add .!);
    system($git, qw/commit -m/, "initial blog commit");
}

1;
