package Riji;
use Puncheur::Lite;

use Encode;
use Text::Xslate;

our $VERSION = 0.01;

__PACKAGE__->setting(
    handle_static => 1,
);
__PACKAGE__->load_plugin(qw/Model ShareDir/);

get '/{page:(?:[-_a-zA-Z0-9]+.html)?}' => sub {
    my ($c, $args) = @_;
    my $page = $args->{page} || 'index.html';
    my $tmpl = $page;
       $tmpl =~ s/html$/tx/;

    local $@;
    my $res = eval {
        $c->render($tmpl, {
            blog => $c->model('Blog'),
        });
    };
    return $res unless my $err = $@;

    if ($err =~ /^Text::Xslate: LoadError: Cannot find/) {
        return $c->res_404;
    }
    else {
        die $err;
    }
};

get '/entry/{name:[-_a-zA-Z0-9]+}.html' => sub {
    my ($c, $args) = @_;

    my $name = $args->{name};
    my $blog = $c->model('Blog');
    my $entry = $blog->entry($name);
    return $c->res_404 unless $entry;

    my $app_name = $c->app_name;
    state $xslate = Text::Xslate->new(
        type => 'text',
        function => {
            c         => sub { $app_name->context },
            uri_for   => sub { $app_name->context->uri_for(@_) },
        }
    );
    my $body = $xslate->render_string($entry->body, {
        entry => $entry,
        blog  => $blog,
    });
    $entry->body($body);
    my $article = $entry->body_as_html;

    my $tmpl = $entry->template // 'entry';
    $tmpl .= '.tx';

    $c->render($tmpl, {
        blog    => $blog,
        entry   => $entry,
        article => $article,
    });
};

get '/atom.xml' => sub {
    my $c = shift;

    my $atom = $c->model('Blog')->atom;
    my $xml = $atom->feed->to_string;
    $c->create_response(200, ['Content-Type' => 'application/atom+xml'], [encode($c->encoding, $xml)]);
};

1;
