package Riji::Model::Entry;
use 5.010;
use warnings;
use utf8;

use Path::Tiny;
use YAML::Tiny;
use Text::Markdown::Discount;
use Time::Piece;

use Git::Repository 'FileHistory';

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        base_dir    => $args{base_dir},
        file        => $args{file},
    }, $class;

    return () unless -f -r $self->file_path;

    $self->_parse_content;
    $self;
}

sub mkdn_dir { 'docs/entry' }
sub base_dir { shift->{base_dir} }
sub file     { shift->{file}     }
sub file_path {
    my $self = shift;
    $self->{file_path} //= path($self->base_dir, $self->mkdn_dir, $self->file);
}
sub content_raw {
    my $self = shift;
    $self->{content_raw} //= $self->file_path->slurp_utf8;
}

sub repo {
    my $self = shift;
    $self->{repo} //= Git::Repository->new(work_tree => $self->{base_dir});
}
sub repo_path {
    my $self = shift;
    $self->file_path->relative($self->base_dir)
}

sub body { shift->{body} }
sub md { shift->{md} //= Text::Markdown::Discount->new }
sub body_as_html {
    my $self = shift;
    $self->{body_as_html} //= $self->md->markdown($self->body);
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

sub file_history {
    my $self = shift;
    $self->{file_history} //= $self->repo->file_history($self->repo_path);
}

sub last_modified_at {
    my $self = shift;
    $self->{last_modified_at} //= localtime($self->file_history->last_modified_at)->datetime;
}

sub created_at {
    my $self = shift;
    $self->{created_at} //= localtime($self->file_history->created_at)->datetime;
}

sub created_by       { shift->file_history->created_by }
sub last_modified_by { shift->file_history->last_modified_by }

sub tags {...}

sub _parse_content {
    my $self = shift;
    my ($header_raw, $body) = split /^---\n/ms, $self->content_raw, 2;

    my $headers = {};
    if (defined $body) {
        local $@;
        $headers = eval {
            YAML::Tiny::Load($header_raw);
        } || {};
        if ($@) {
            ($header_raw, $body) = ('', $self->content_raw);
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
