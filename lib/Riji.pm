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
    $c->render('index.tx', {
        blog => $c->model('Blog'),
    });
};

get '/archives.html' => sub {
    my $c = shift;
    $c->render('archives.tx', {
        blog => $c->model('Blog'),
    });
};

get '/entry/{name:[-_a-zA-Z0-9]+}.html' => sub {
    my ($c, $args) = @_;

    my $name = $args->{name};
    my $blog = $c->model('Blog');
    my $entry = $blog->entry($name);
    return $c->res_404 unless $entry;

    my $template = $entry->template // 'entry';
    $template .= '.tx';

    $c->render($template, {
        blog  => $blog,
        entry => $entry,
    });
};

get '/atom.xml' => sub {
    my $c = shift;

    my $atom = $c->model('Blog')->atom;
    my $xml = $atom->feed->to_string;
    $c->create_response(200, ['Content-Type' => 'application/atom+xml'], [encode($c->encoding, $xml)]);
};

1;
