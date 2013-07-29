package Riji::Model::Blog;
use feature ':5.10';
use strict;
use warnings;

use File::Spec;
use Git::Repository 'FileHistory';
use List::UtilsBy qw/rev_sort_by rev_nsort_by/;
use Path::Tiny 'path';

use Riji::Model::Atom;
use Riji::Model::Entry;
use Riji::Model::Tag;

use Mouse;

has base_dir => (is => 'ro', required => 1);
has author   => (is => 'ro', required => 1);
has title    => (is => 'ro', required => 1);
has site_url => (
    is       => 'ro',
    isa      => 'URI',
    required => 1
);

has fqdn => (
    is      => 'ro',
    lazy    => 1,
    default => sub {shift->site_url->host},
);

has tag_uri_specific_prefix => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $pref = shift->site_url->path;
        $pref =~ s!/$!!;
        $pref =~ s!^/!!;
        $pref =~ s!/!-!g;
        $pref .= ':' if $pref;
        $pref;
    },
);


has article_dir => (
    is => 'ro',
    default => 'article',
);

has entry_dir => (
    is => 'ro',
    default => 'article/entry',
);

has article_path => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        path($self->base_dir, $self->article_dir);
    },
);

has repo => (
    is   => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Git::Repository->new(work_tree => $self->base_dir);
    },
);

has branch => (
    is      => 'ro',
    default => 'master',
);

has atom => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Riji::Model::Atom->new(
            blog => $self
        );
    },
);

has tag_map => (
    is      => 'ro',
    isa     => 'HashRef[Riji::Model::Tag]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my %map;
        for my $entry (@{ $self->entries }) {
            for my $tag (@{ $entry->raw_tags }) {
                $map{$tag} ||= Riji::Model::Tag->new(name => $tag);
                push @{$map{$tag}->entries}, $entry;
            }
        }
        \%map;
    },
);

has tags => (
    is      => 'ro',
    isa     => 'ArrayRef[Riji::Model::Tag]',
    lazy    => 1,
    default => sub {
        [rev_nsort_by {$_->count} values %{ shift->tag_map }]
    },
);

no Mouse;

sub entries {
    my ($self, @args) = @_;

    $self->{entries} ||= [
        rev_sort_by { $_->published_at->datetime . $_->file }
        grep        { $_ && !$_->is_draft }
        map         { $self->entry($_->basename) }
        grep        { -f -r }
        $self->article_path->child('entry')->children
    ];
    return $self->{entries} unless @args;

    $self->_search_entries(@args);
}

sub entry {
    my ($self, $file) = @_;

    my $entry = Riji::Model::Entry->new(
        file => File::Spec->catfile('entry', $file),
        blog => $self,
    );
    return () unless -f -r $entry->file_path;

    $entry;
}

sub article {
    my ($self, $file, $opt) = @_;

    my $article = Riji::Model::Article->new(
        file => $file,
        blog => $self,
        %$opt,
    );
    return () unless -f -r $article->file_path;
    return () if !$article->paginate && $article->page;

    $article;
}

sub tag {
    my ($self, $tag) = @_;
    $self->tag_map->{$tag};
}

# _search_entries(tag => 'hoge', sort_by => 'last_updated_at', sort_order => 'desc', limit => 10);
sub _search_entries {
    my $self = shift;
    my %opt = @_ == 1 ? %{$_[0]} : @_;
    my @entries = @{ $self->entries };

    if (my $tag = $opt{tag}) {
        @entries = grep { grep {$_ eq $tag} @{ $_->raw_tags } } @entries;
    }

    if (my $sort_by = $opt{sort_by}) {
        my @enable_fields = qw/published_at last_modified_at title/;
        if (grep {$sort_by eq $_} @enable_fields) {
            if ($sort_by eq 'last_modified_at') {
                @entries = rev_sort_by {$_->last_modified_at->datetime . $_->title} @entries;
            }
            elsif ($sort_by ne 'published_at') {
                @entries = rev_sort_by {$_->title} @entries;
            }
        }
        else {
            warn "$sort_by is unknown sort item";
        }
    }

    my $sort_order = lc($opt{sort_order} || '');
    if ($sort_order && ! grep {$sort_order eq $_} qw/asc desc/) {
        warn "$sort_order is unknown sort_order";
        $sort_order = undef;
    }
    if ($opt{sort_by} && !$sort_order) {
        $sort_order = {
            last_modified_at => 'desc',
            published_at     => 'desc',
            title            => 'asc',
        }->{$opt{sort_by}};
    }
    $sort_order ||= 'desc';
    @entries = reverse @entries if $sort_order eq 'asc';

    if (my $limit = $opt{limit}) {
        @entries = splice @entries, 0, $limit;
    }
    [@entries];
}

1;
