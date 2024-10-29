package Riji::Model::Atom;
use feature ':5.10';
use strict;
use warnings;

use Time::Piece;
use URI::tag;
use XML::FeedPP;

use Riji::Model::Entry;

use Mouse;

has blog => (
    is       => 'ro',
    isa      => 'Riji::Model::Blog',
    required => 1,
    handles  => [qw/fqdn author title entry_dir site_url repo/],
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
                description => {
                    '#text' => \$_->html_body_without_title, #pass scalar ref for CDATA
                    -type   => 'html',
                },
                pubDate     => $_->last_modified_at->epoch,
                author      => $_->created_by,
                guid        => $_->tag_uri->as_string,
                published   => XML::FeedPP::Util::epoch_to_w3cdtf($_->published_at->epoch),
                link        => $_->url,
            } } @{ $self->blog->entries(sort_by => 'last_modified_at') }
        ]
    },
);

has feed => (
    is => 'ro',
    default => sub {
        my $self = shift;

        my $file_history = $self->repo->file_history($self->entry_dir, {branch => $self->blog->branch});

        my $updated_at = $file_history->updated_at;
        my $created_at = $file_history->created_at;

        my $tag_uri = URI->new('tag:');
        $tag_uri->authority($self->fqdn);
        $tag_uri->date(gmtime($created_at)->strftime('%Y-%m-%d'));
        $tag_uri->specific($self->blog->tag_uri_specific_prefix);
        my $feed = XML::FeedPP::Atom::Atom10->new(
            link    => $self->site_url,
            author  => {name => $self->author},
            title   => $self->title,
            pubDate => $updated_at,
            id      => $tag_uri->as_string,
            generator => {
                '#text'  => 'Perl Riji',
                -version => $Riji::VERSION,
                -uri     => 'https://github.com/Songmu/p5-Riji',
            },
        );
        $feed->add_item(%$_) for @{ $self->entry_datas };
        $feed->sort_item;

        $feed;
    },
);

no Mouse;

1;
