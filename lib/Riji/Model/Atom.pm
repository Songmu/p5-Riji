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
    handles  => [qw/base_dir fqdn author title article_dir site_url article_path repo entries/],
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
                pubDate     => $_->last_modified_at->epoch,
                author      => $_->created_by,
                guid        => $_->tag_uri->as_string,
                published   => $_->created_at->strftime('%Y-%m-%dT%M:%M:%S%z'),
                link        => $_->url,
            } } @{ $self->entries }
        ]
    },
);

has feed => (
    is => 'ro',
    default => sub {
        my $self = shift;

        my $last_modified_at = $self->repo->file_history($self->article_dir, {branch => $self->blog->git_branch})->last_modified_at;
        my $tag_uri = URI->new('tag:');
        $tag_uri->authority($self->fqdn);
        $tag_uri->date(gmtime($last_modified_at)->strftime('%Y-%m-%d'));
        $tag_uri->specific($self->blog->tag_uri_specific_prefix);
        my $feed = XML::FeedPP::Atom::Atom10->new(
            link    => $self->site_url,
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
