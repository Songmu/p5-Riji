package Riji::CLI::Publish;
use feature ':5.10';
use strict;
use warnings;

use File::Temp qw/tempdir/;
use File::Copy::Recursive qw/rmove/;
use Path::Tiny qw/path/;

use Wallflower;
use Wallflower::Util qw/links_from/;
use URI;

use Riji;

sub run {
    my ($class, @argv) = @_;

    my $app = Riji->new;
    my $work_dir = tempdir;

    say "start downloading";
    my $wallflower = Wallflower->new(
        application => $app->to_psgi,
        destination => $work_dir,
    );
    my %seen;
    my @queue = ('/');
    while (@queue) {
        my $url = URI->new( shift @queue );
        next if $seen{ $url->path }++;
        next if $url->scheme && ! eval { $url->host =~ /localhost/ };

        # get the response
        my $response = $wallflower->get($url);
        my ( $status, $headers, $file ) = @$response;

        # tell the world
        printf "$status %s%s\n", $url->path, $file && " => $file [${\-s $file}]";

        # obtain links to resources
        if ( $status eq '200' ) {
            push @queue, links_from( $response => $url );
        }
    }

    say "start replace urls";
    my $conf = $app->config;
    my $replace_from = quotemeta "http://localhost";
    my $replace_to   = $conf->{site_url};
       $replace_to =~ s!/+$!!;
    my $walk; $walk = sub {
        my $dir = shift;
        for my $file ($dir->children) {
            $walk->($file) if -d $file;
            next unless $file =~ /\.(?:js|css|html|xml)$/;

            my $content = $file->slurp_utf8;
            $content =~ s/$replace_from/$replace_to/msg;
            $file->spew_utf8($content);
        }
    };
    $walk->(path $work_dir);

    rmove $work_dir, $conf->{publish_dir} // 'blog';
    say "done.";
}

1;
