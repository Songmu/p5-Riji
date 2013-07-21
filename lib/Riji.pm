package Riji;
use Puncheur::Lite;
use Path::Tiny;
use Text::Markdown::Discount;

use Riji::Model::Entry;

our $VERSION = 0.01;

__PACKAGE__->setting(
    handle_static => 1,
);

get '/{index:(?:index.html)?}' => sub {
    my $c = shift;
    $c->render('index.tx', { greeting => "Hello" });
};

get '/entry/:name.html' => sub {
    my ($c, $args) = @_;

    my $name = $args->{name};
    return $c->res_404 if $name =~ /[^-_.a-zA-Z0-9]/;

    my $md_file = path($c->base_dir)->child('docs', 'entry', "$name.md");

    return $c->res_404 unless -f $md_file;

    my $entry = Riji::Model::Entry->new($md_file);

    $c->render('entry.tx', {
        title   => $entry->title,
        article => $entry->as_html,
    });
};

1;
