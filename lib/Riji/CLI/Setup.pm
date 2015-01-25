package Riji::CLI::Setup;
use feature ':5.10';
use strict;
use warnings;

use Cwd qw/getcwd/;
use File::Copy qw/copy/;
use File::Copy::Recursive qw/dircopy/;
use File::Spec;
use IPC::Cmd ();
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

    my $recurse644 = sub {
        my $dir = shift;
        my $itr = $dir->iterator({recurse => 1});
        while (my $file = $itr->()) {
            next unless -f $file;
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

    my $cpanfile = path($setup_dir, 'cpanfile');
    unless (-f $cpanfile) {
        $cpanfile->spew(qq{requires "Riji", "$Riji::VERSION";\n});
    }

    my $gitignore = path($setup_dir, '.gitignore');
    unless (-f $gitignore) {
        $gitignore->spew(".*\n!.gitignore\nlocal/\n*~\n*.swp\n");
    }

    my $git = IPC::Cmd::can_run('git') or die "git not found.\n";

    unless (-e path($setup_dir)->child('.git')) {
        system($git, qw!init!);
    }
    system($git, qw!add .!);
    system($git, qw/commit -m/, "initial blog commit");
}

1;
