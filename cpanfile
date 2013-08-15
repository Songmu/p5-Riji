requires 'App::Wallflower';
requires 'Data::Section::Simple';
requires 'File::Copy::Recursive';
requires 'File::Which';
requires 'Git::Repository';
requires 'Git::Repository::FileHistory', '0.03';
requires 'HTTP::Date';
requires 'List::UtilsBy';
requires 'MIME::Base32';
requires 'Mouse';
requires 'Net::EmptyPort';
requires 'Object::Container';
requires 'Path::Tiny';
requires 'Plack';
requires 'Puncheur::Lite';
requires 'Puncheur::Runner';
requires 'Router::Simple::Sinatraish';
requires 'String::CamelCase';
requires 'Text::Markdown::Discount', '0.10';
requires 'Text::Markup::Any';
requires 'Text::Xslate';
requires 'Time::Piece';
requires 'URI';
requires 'URI::tag';
requires 'XML::FeedPP';
requires 'YAML::Tiny';
requires 'perl', '5.010';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
};
