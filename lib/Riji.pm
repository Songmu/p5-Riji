package Riji;
use Puncheur::Lite;
use Path::Tiny;

our $VERSION = 0.01;

__PACKAGE__->setting(
    handle_static => 1,
);

get '/' => sub {
    my $c = shift;
    $c->render('index.tx', { greeting => "Hello" });
};

get '/entry/:name' => sub {
    my ($c, $args) = @_;

    my $name = $args->{name};

    my $md_file = path($c->base_dir)->child('docs', '2013020201.md');
    my $article = $md_file->slurp;

    $c->create_response(200, ['Content-Type' => 'text/plain'], [$article]);
};

1;
