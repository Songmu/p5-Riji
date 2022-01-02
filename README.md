[![Actions Status](https://github.com/Songmu/p5-Riji/workflows/test/badge.svg)](https://github.com/Songmu/p5-Riji/actions) [![Coverage Status](https://img.shields.io/coveralls/Songmu/p5-Riji/master.svg?style=flat)](https://coveralls.io/r/Songmu/p5-Riji?branch=master)
# NAME

Riji - Simple, git based blog tool

# SYNOPSIS

    % cpanm -qn Riji           # install `riji` cli
    % rjji setup               # setup new blog site
    % $EDITOR riji.yml         # adjust configuration
    % riji new-entry your-slug # create new blog entry in Markdown
    % git add article/ && git commit -m "add new entry"
    % riji server              # local server for staging starts on the port 3650.
    % riji publish             # static site will be created in the ./riji directory

# TUTORIAL

Japanese: [http://songmu.github.io/p5-Riji/blog/](http://songmu.github.io/p5-Riji/blog/)

English [http://perlmaven.com/blogging-with-riji](http://perlmaven.com/blogging-with-riji)

# DESCRIPTION

Riji is a static site generator using Markdown, featuring RSS generation from git history.

'Riji'(日记) means diary in Chinese.

# FEATURES

- Static site generation with Markdown files.
- All operations can be performed with the cli "riji".
- Commits Markdown files to your git repository and automatically generates RSS from the git log.
- Name of markdown file will be directly mapped to the URL as html.
- YAML frontmatter can be written optionally in Markdown file for meta-information, like tags, etc.
- Customizable site template with Text::Xslate Kolon format.
- Kolon template notation can also be used in Markdown files.
- Your own template macros can be defined in the functions.pl file.

# DOCKER

docker container is also available.

    % docker run --rm -v $(PWD):/riji -v $(PWD)/.git:/riji/.git -i ghcr.io/songmu/riji publish

# LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# THANKS

Thanks to Gabor Szabo <szabgab@gmail.com> for great English tutorial.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>
