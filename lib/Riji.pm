package Riji;
use Puncheur::Lite;

use Encode;
use Text::Markdown::Discount;

use Riji::Model::Entry;
use Riji::Model::Atom;

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

    my $entry = Riji::Model::Entry->new(
        base_dir => $c->base_dir,
        file     => "$name.md",
    );
    return $c->res_404 unless $entry;

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

    my $atom = Riji::Model::Atom->new(
        base_dir => $c->base_dir,
        fqdn     => 'riji.songmu.jp',
    );

    my $xml = $atom->feed->to_string;
    $c->create_response(200, ['Content-Type' => 'application/atom+xml'], [encode($c->encoding, $xml)]);
};

1;
