#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin::libs;

use Path::Tiny;
use Time::Piece;
use URI::tag;
use XML::FeedPP;

use Riji;
use Riji::Model::Entry;

my $base_dir = Riji->new->base_dir;
my $domain   = 'riji.songmu.com';
my $url_root = "http://$domain/";

my $target_dir = 'docs/entry';
my $mkdn_dir = path($base_dir, $target_dir);

my @entries;
for my $file ( grep { -f -r $_ && $_ =~ /\.md$/ } $mkdn_dir->children ){
    my $path = $file->relative($mkdn_dir);
    my $entry = Riji::Model::Entry->new(
        file     => $path,
        base_dir => $base_dir,
    );

    my $entry_path = $file->basename;
    $entry_path =~ s/\.md$//;
    $entry_path = "entry/$entry_path";
    my $url = $url_root . $entry_path . '.html';
    my $tag_uri = URI->new('tag:');
    $tag_uri->authority($domain);
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

my $gm_now = gmtime;
my $tag_uri = URI->new('tag:');
$tag_uri->authority($domain);
$tag_uri->date($gm_now->strftime('%Y-%m-%d'));
my $feed = XML::FeedPP::Atom::Atom10->new(
    link    => $url_root,
    author  => 'Masayuki Matsuki',
    title   => "Songmu's Riji",
    pubDate => $gm_now->epoch,
    id      => $tag_uri->as_string,
);
$feed->add_item(%$_) for @entries;
$feed->sort_item;

path('atom.xml')->spew_utf8($feed->to_string);
