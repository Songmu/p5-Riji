package Riji;
use Puncheur::Lite;

use Encode;
use Text::Xslate;

our $VERSION = 0.01;

__PACKAGE__->setting(
    handle_static => 1,
);
__PACKAGE__->load_plugin(qw/Model ShareDir/);

get '/{match:(?:[-_a-zA-Z0-9]+(?:\.[0-9]+)?.html)?}' => sub {
    my ($c, $args) = @_;

    my $match = $args->{match} || 'index.html';
    my ($basename, $page) = $match =~ m!^([-_a-zA-Z0-9]+)(?:\.([0-9]+))?\.html$!;
    my $tmpl = "$basename.tx";

    # 対応するarticleがあったらそれを使うパターンでもいいかも
    local $@;
    my $res = eval {
        $c->render($tmpl, {
            blog => $c->model('Blog'),
            page => $page,
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

    my $tmpl = $entry->template // 'entry';
    $tmpl .= '.tx';

    $c->render($tmpl, {
        blog    => $blog,
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
