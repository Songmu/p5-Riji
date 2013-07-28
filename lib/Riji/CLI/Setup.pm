package Riji::CLI::Setup;
use 5.010;
use warnings;

use Cwd qw/getcwd/;
use File::Copy qw/copy/;
use File::Copy::Recursive qw/dircopy/;
use File::Spec;

use Riji;

sub run {
    my ($class, @argv) = @_;

    my $share_dir = Riji->share_dir;
    my $setup_dir = getcwd;

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

    my $repo = Riji->new->model('Blog')->repo;
    $repo->run('init');
    $repo->run('add .');
}

1;
