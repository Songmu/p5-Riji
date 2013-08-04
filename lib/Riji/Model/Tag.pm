package Riji::Model::Tag;
use feature ':5.10';
use strict;
use warnings;

use Encode;
use MIME::Base32 'RFC';

use Mouse;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has entries => (
    is => 'rw',
    isa => 'ArrayRef[Riji::Model::Entry]',
    lazy    => 1,
    default => sub { [] },
);

has count => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        scalar @{ shift->entries };
    },
);

has _encoded_name => (
    is => 'ro',
    default => sub {
        my $name = shift->name;
        return $name unless $name =~ /[^-_a-zA-Z0-9]/ms;

        'b32.'.MIME::Base32::encode(encode_utf8 $name);
    }
);

has site_path => (
    is      => 'ro',
    default => sub { '/tag/' . shift->_encoded_name . '.html' },
);

no Mouse;

sub normalize_tag {
    my ($class, $tag) = @_;

    if ($tag =~ s/^b32\.//) {
        return decode_utf8 MIME::Base32::decode($tag);
    }
    $tag;
}

1;
