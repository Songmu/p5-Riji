package Riji::CLI;
use 5.010;
use warnings;

use File::Which ();
use Getopt::Long ();
use Plack::Util ();
use String::CamelCase ();

sub run {
    my ($self, @args) = @_;

    local @ARGV = @args;
    my @commands;
    my $p = Getopt::Long::Parser->new(
        config => [ "no_ignore_case", "pass_through" ],
    );
    $p->getoptions(
        "h|help"   => sub { unshift @commands, 'help' },
        'version!' => \my $version,
    );
    if ($version) {
        require Riji;
        say "Riji: $Riji::VERSION"; exit 0;
    }
    push @commands, @ARGV;

    my $cmd = shift @commands || 'help';
    if (my $cmd = File::Which::which("riji-$cmd")) {
        exec $cmd, @commands;
    }

    $cmd =~ s/-/_/g;
    my $class = String::CamelCase::camelize $cmd;

    local $@;
    $class = eval { Plack::Util::load_class($class, 'Riji::CLI') };
    if (my $err = $@) {
        if ($err =~ m!Can't locate Riji/CLI!) {
            warn "sub command `$cmd` not found\n"; exit 1;
        }
        die $@;
    }
    $class->run(@commands);
}

1;
