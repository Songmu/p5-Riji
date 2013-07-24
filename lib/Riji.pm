package Riji;
use Puncheur::Lite;

use Encode;

our $VERSION = 0.01;

__PACKAGE__->setting(
    handle_static => 1,
);
__PACKAGE__->load_plugin(qw/Model/);

get '/{index:(?:index.html)?}' => sub {
    my $c = shift;
    $c->render('index.tx', { greeting => "Hello" });
};

get '/archives.html' => sub {
    my $c = shift;
    $c->render('archives.tx', {
        entries => $c->model('Blog')->entries,
    });
};

get '/entry/{name:[-_a-zA-Z0-9]+}.html' => sub {
    my ($c, $args) = @_;

    my $name = $args->{name};
    my $entry = $c->model('Blog')->entry($name);
    return $c->res_404 unless $entry;

    $c->render('entry.tx', {
        entry   => $entry,
    });
};

get '/atom.xml' => sub {
    my $c = shift;

    my $atom = $c->model('Blog')->atom;
    my $xml = $atom->feed->to_string;
    $c->create_response(200, ['Content-Type' => 'application/atom+xml'], [encode($c->encoding, $xml)]);
};

1;
