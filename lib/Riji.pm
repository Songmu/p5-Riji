package Riji;
use Puncheur::Lite;

use Encode;
use File::Spec;
use YAML::Tiny ();

our $VERSION = 0.01;

__PACKAGE__->setting(
    handle_static => 1,
);
__PACKAGE__->load_plugin(qw/Model ShareDir/);

sub load_config {
    my $self = shift;
    my $file = File::Spec->catfile($self->base_dir, 'riji.yml');
    unless (-e $file) {
        warn 'config file not found';
        return +{};
    }
    YAML::Tiny::LoadFile($file);
}

get '/{match:(?:[a-zA-Z0-9][-_a-zA-Z0-9]*(?:\.[0-9]+)?.html)?}' => sub {
    my ($c, $args) = @_;

    my $match = $args->{match} || 'index.html';
    my ($basename, $page) = $match =~ m!^([-_a-zA-Z0-9]+)(?:\.([0-9]+))?\.html$!;

    my $blog    = $c->model('Blog');
    my $article = $blog->article($basename, {$page ? (page => $page) : ()});

    my $tmpl = $basename;
    $tmpl = $article->template if $article && $article->template;
    $tmpl .= '.tx';

    local $@;
    my $res = eval {
        $c->render($tmpl, {
            blog    => $blog,
            page    => $page,
            article => $article,
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

    my $tmpl = $entry->template // '_entry';
    $tmpl .= '.tx';

    $c->render($tmpl, {
        blog    => $blog,
        entry   => $entry,
    });
};

get '/tag/:tag.html' => sub {
    my ($c, $args) = @_;

    my $tag = $args->{tag};
    my $blog = $c->model('Blog');
    $tag = $blog->tag($tag);
    return $c->res_404 unless $tag;

    $c->render('_tag.tx', {
        blog  => $blog,
        tag   => $tag,
    });
};

get '/atom.xml' => sub {
    my $c = shift;

    my $atom = $c->model('Blog')->atom;
    my $xml = $atom->feed->to_string;
    $c->create_response(200, ['Content-Type' => 'application/atom+xml'], [encode($c->encoding, $xml)]);
};

1;
__END__

=encoding utf-8

=head1 NAME

Riji - Simple, git based blog tool

=head1 SYNOPSIS

    % rjji-setup
    % riji-server

=head1 DESCRIPTION

Riji is a simple blog tool.

'riji' means diary in Chinese.

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

