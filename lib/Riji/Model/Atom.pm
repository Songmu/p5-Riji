package Riji::Model::Atom;
use strict;
use warnings;
use utf8;

use Time::Piece;
use URI::tag;
use XML::FeedPP;

use Riji::Model::Entry;

use Mouse;

has blog => (
    is       => 'ro',
    isa      => 'Riji::Model::Blog',
    required => 1,
    handles  => [qw/base_dir fqdn author title mkdn_dir url_root mkdn_path repo entries/],
    weak_ref => 1,
);

has entry_datas => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [
            map { +{
                title       => $_->title,
                description => \$_->body_as_html, #pass scalar ref for CDATA
                pubDate     => $_->last_modified_at,
                author      => $_->created_by,
                guid        => $_->tag_uri->as_string,
                published   => $_->created_at,
                link        => $_->url,
            } } @{ $self->entries }
        ]
    },
);

has feed => (
    is => 'ro',
    default => sub {
        my $self = shift;

        my $last_modified_at = $self->repo->file_history($self->mkdn_dir)->last_modified_at;
        my $tag_uri = URI->new('tag:');
        $tag_uri->authority($self->fqdn);
        $tag_uri->date(gmtime($last_modified_at)->strftime('%Y-%m-%d'));
        my $feed = XML::FeedPP::Atom::Atom10->new(
            link    => $self->url_root,
            author  => $self->author,
            title   => $self->title,
            pubDate => $last_modified_at,
            id      => $tag_uri->as_string,
        );
        $feed->add_item(%$_) for @{ $self->entry_datas };
        $feed->sort_item;

        $feed;
    },
);

no Mouse;

1;
