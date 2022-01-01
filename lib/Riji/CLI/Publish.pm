package Riji::CLI::Publish;
use feature ':5.10';
use strict;
use warnings;

use Errno qw(:POSIX);
use Path::Tiny qw/path tempdir/;
use File::Copy::Recursive qw/dircopy/;

use Wallflower::Util qw/links_from/;
use Wallflower;
use URI;

use Riji;

sub run {
    my ($class, @argv) = @_;

    my $app = Riji->new;
    my $conf = $app->config;
    my $blog = $app->model('Blog');
    my $repo = $blog->repo;
    my $force = grep {$_ eq '--force'} @argv;

    # `git symbolic-ref --short` is available after git 1.7.10, so care older version.
    my $current_branch = $repo->run(qw/symbolic-ref HEAD/);
       $current_branch =~ s!refs/heads/!!;
    my $publish_branch = $blog->branch;
    unless ($force){
        my $force_announce = "or you can use --force option\n";
        if ($publish_branch ne $current_branch) {
            die "You need at publish branch [$publish_branch], so `git checkout $publish_branch` beforehand $force_announce";
        }

        if ( my $untracked = $repo->run(qw/ls-files --others --exclude-standard --/, $blog->entry_dir) ) {
            die "Unknown local files:\n$untracked\n\ngit add them, update .gitignore $force_announce";
        }

        if (my $uncommited = $repo->run(qw/diff HEAD --name-only --/, $blog->entry_dir) ) {
            die "Found uncommited changes:\n$uncommited\n\ncommit them beforehand $force_announce";
        }
    }

    say "start scanning";
    my $dir = $conf->{publish_dir} // 'blog';
    unless (mkdir $dir or $! == EEXIST ){
        printf "can't create $dir: $!\n";
    }

    my $work_dir = tempdir(CLEANUP => 1);

    my $site_url   = $blog->site_url;
    my $mount_path = $site_url->path;
       $mount_path = '' if $mount_path eq '/';

    my $wallflower = Wallflower->new(
        application => $app->to_psgi,
        destination => $work_dir . '',
        url         => $site_url,
    );
    my $host_reg = quotemeta $site_url->host;

    my %seen;
    my @queue = ($mount_path || '/');
    while (@queue) {
        my $url = URI->new( shift @queue );
        next if $seen{ $url->path }++;
        next if $url->scheme && ! eval { $url->host and $url->host =~ /(?:localhost|$host_reg)/ };

        # get the response
        my $response = $wallflower->get($url);
        my ( $status, $headers, $file ) = @$response;

        # tell the world
        printf "$status %s %s\n", $url->path, $file && "[${\-s $file}]";

        # obtain links to resources
        if ( $status eq '200' ) {
            push @queue, links_from( $response => $url );
        }

        if ($file && $file =~ /\.(?:js|css|html|xml)$/) {
            $file = path($file);
            my $content = $file->slurp_utf8;
            $file->spew_utf8($content);
        }
    }

    my $copy_from = $work_dir;
    if ($mount_path) {
        $mount_path =~ s!^/+!!;
        $copy_from = path $work_dir, $mount_path;
    }
    dircopy $copy_from.'', $dir;

    say "done.";
}

1;
