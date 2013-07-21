package Riji::Model::Entry;
use 5.010;
use warnings;
use utf8;

use Path::Tiny;
use YAML::Tiny;
use Text::Markdown::Discount;

sub new {
    my ($class, $file) = @_;
    die 'file not found' unless -f -r $file;
    my $self = bless {
        content_raw => path($file)->slurp_utf8,
    }, $class;
    $self->_parse_content;
    $self;
}

sub body { shift->{body} }

sub body_as_html {
    my $self = shift;

    state $md = Text::Markdown::Discount->new;
    $self->{body_as_html} //= $md->markdown($self->body);
}

sub headers {
    my ($self, $key) = @_;
    if (defined $key){
        return $self->{headers}{$key};
    }
    else{
        return $self->{headers};
    }
}

sub title {
    my $self = shift;
    $self->{title} //= $self->headers('title') // sub {
        for my $line ( split /\n/, $self->body ){
            if ( $line =~ /^#/ ){
                $line =~ s/^[#\s]+//;
                $line =~ s/[#\s]+$//;
                return $line;
            }
        }
    }->() // 'unknown';
}

sub _parse_content {
    my $self = shift;
    my ($header_raw, $body) = split /^---\n/ms, $self->{content_raw}, 2;

    my $headers = {};
    if (defined $body) {
        local $@;
        $headers = eval {
            YAML::Tiny::Load($header_raw);
        } || {};
        if ($@) {
            ($header_raw, $body) = ('', $self->{content_raw});
        }
    }
    else {
        ($header_raw, $body) = ('', $header_raw);
    }

    $self->{body}       = $body;
    $self->{header_raw} = $header_raw;
    $self->{headers}    = $headers;
    $self;
}

1;
