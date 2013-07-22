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

get '/entry/:name.html' => sub {
    my ($c, $args) = @_;

    my $name = $args->{name};
    return $c->res_404 if $name =~ /[^-_.a-zA-Z0-9]/;

    my $entry = $c->model('Blog')->entry("$name.md");
    return $c->res_404 unless -f -r $entry->file_path;

    $c->render('entry.tx', {
        title   => $entry->title,
        article => $entry->body_as_html,
        last_modified_at => $entry->last_modified_at,
        last_modified_by => $entry->last_modified_by,
        created_at       => $entry->created_at,
        created_by       => $entry->created_by,
    });
};

get '/atom.xml' => sub {
    my $c = shift;

    my $atom = $c->model('Blog')->atom;
    my $xml = $atom->feed->to_string;
    $c->create_response(200, ['Content-Type' => 'application/atom+xml'], [encode($c->encoding, $xml)]);
};

1;
