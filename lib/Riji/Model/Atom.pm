package Riji::Model::Atom;
use strict;
use warnings;
use utf8;

use Git::Repository 'FileHistory';
use Path::Tiny;
use Time::Piece;
use URI::tag;
use XML::FeedPP;

use Riji::Model::Entry;

sub new {
    my ($class, %args) = @_;
    bless {%args}, $class;
}

sub base_dir { shift->{base_dir} }
sub fqdn     { shift->{fqdn}   }
sub url_root { "http://@{[shift->fqdn]}/" }

sub mkdn_dir {
    my $self = shift;
    $self->{mkdn_dir} //= path($self->base_dir, 'docs/entry');
}

sub repo {
    my $self = shift;
    $self->{repo} //= Git::Repository->new(work_tree => $self->base_dir);
}

sub entries {
    my $self = shift;

    $self->{entries} ||= do {
        my @entries;
        for my $file ( grep { -f -r $_ && $_ =~ /\.md$/ } $self->mkdn_dir->children ){
            my $path = $file->relative($self->mkdn_dir);
            my $entry = Riji::Model::Entry->new(
                file     => $path,
                base_dir => $self->base_dir,
            );

            my $entry_path = $file->basename;
            $entry_path =~ s/\.md$//;
            $entry_path = "entry/$entry_path";
            my $url = $self->url_root . $entry_path . '.html';
            my $tag_uri = URI->new('tag:');
            $tag_uri->authority($self->fqdn);
            $tag_uri->date(localtime($entry->last_modified_at)->strftime('%Y-%m-%d'));
            $tag_uri->specific(join('-',split(m{/},$entry_path)));

            push @entries, {
                title       => $entry->title,
                description => \$entry->body_as_html, #pass scalar ref for CDATA
                pubDate     => $entry->last_modified_at,
                author      => $entry->created_by,
                guid        => $tag_uri->as_string,
                published   => $entry->created_at,
                link        => $url,
            } unless $entry->headers('draft');
        }
        \@entries;
    };
}

sub feed {
    my $self = shift;

    my $last_modified_at = $self->repo->file_history('docs/entry')->last_modified_at;
    my $tag_uri = URI->new('tag:');
    $tag_uri->authority($self->fqdn);
    $tag_uri->date(gmtime($last_modified_at)->strftime('%Y-%m-%d'));
    my $feed = XML::FeedPP::Atom::Atom10->new(
        link    => $self->url_root,
        author  => 'Masayuki Matsuki',
        title   => "Songmu's Riji",
        pubDate => $last_modified_at,
        id      => $tag_uri->as_string,
    );
    $feed->add_item(%$_) for @{ $self->entries };
    $feed->sort_item;

    $feed;
}

1;
