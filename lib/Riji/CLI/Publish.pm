package Riji::CLI::Publish;
use 5.010;
use strict;
use warnings;

use File::Which;
use File::Copy::Recursive qw/rmove/;
use Net::EmptyPort;
use Path::Tiny;

use Riji;

sub run {
    my ($class, @argv) = @_;
    my $wget = which 'wget' or die "wget is required for publish\n";

    say "detecting empty port";
    my $port = empty_port;
    if (my $pid = fork) {
        if (Net::EmptyPort::wait_port($port)) {
            say "start downloading";
            system $wget, qw/-r -np -q/, "http://localhost:$port";
        }
        kill 'INT', $pid;
        wait;
    }
    elsif ($pid == 0) {
        require Plack::Loader;
        my $loader = Plack::Loader->auto(port => $port);
        $loader->run(Riji->to_psgi);
    }
    else {
        die "fork failed: $!";
    }

    my $work_dir = path("localhost:$port");
    die 'downloading failed' unless -e $work_dir;
    say "start replace urls";
    my $replace_from = quotemeta "http://localhost:$port";
    my $replace_to   = Riji->new->config->{site_url};
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
    $walk->($work_dir);

    rmove $work_dir, 'blog';
    say "done.";
}

1;
