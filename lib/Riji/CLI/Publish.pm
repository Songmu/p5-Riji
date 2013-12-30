package Riji::CLI::Publish;
use feature ':5.10';
use strict;
use warnings;

use Errno qw(:POSIX);
use Path::Tiny;
use Wallflower;
use Wallflower::Util qw/links_from/;
use URI;

use Riji;

sub run {
    my ($class, @argv) = @_;

    my $app = Riji->new;
    my $conf = $app->config;

    say "start downloading";
    my $replace_from = quotemeta "http://localhost";
    my $replace_to   = $conf->{site_url};
       $replace_to =~ s!/+$!!;

    my $dir = $conf->{publish_dir} // 'blog';
    unless (mkdir $dir or $! == EEXIST ){
        printf "can't create $dir: $!\n";
    }
    my $wallflower = Wallflower->new(
        application => $app->to_psgi,
        destination => $dir,
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
        printf "$status %s %s\n", $url->path, $file && "[${\-s $file}]";

        # obtain links to resources
        if ( $status eq '200' ) {
            push @queue, links_from( $response => $url );
        }

        if ($file && $file =~ /\.(?:js|css|html|xml)$/) {
            $file = path($file);
            my $content = $file->slurp_utf8;
            $content =~ s/$replace_from/$replace_to/msg;
            $file->spew_utf8($content);
        }
    }
    say "done.";
}

1;
