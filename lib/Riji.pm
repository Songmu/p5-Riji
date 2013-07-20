package Riji;
use Puncheur::Lite;
use Path::Tiny;
use Text::Markdown::Discount;

our $VERSION = 0.01;

__PACKAGE__->setting(
    handle_static => 1,
);

get '/' => sub {
    my $c = shift;
    $c->render('index.tx', { greeting => "Hello" });
};

get '/entry/:name.html' => sub {
    my ($c, $args) = @_;

    my $name = $args->{name};
    return $c->res_404 if $name =~ /[^-_.a-zA-Z0-9]/;

    my $md_file = path($c->base_dir)->child('docs',  "$name.md");

    return $c->res_404 unless -f $md_file;

    my $article = $md_file->slurp;

    state $md = Text::Markdown::Discount->new;
    $article = $md->markdown($article);

    $c->render('entry.tx', {
        article => $article,
    });
};

1;
