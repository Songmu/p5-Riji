# 001. Rijiのセットアップ

RijiはシンプルなBlogツールです。「日記」の中国語のピンイン発音表記が<span lang="zh-cn">rìjì</span>であることに由来しています。以下の様な特色があります。

- Markdownがサイトになる
- gitで管理する
- gitの情報を元にRSS(Atom)が自動的に作られる

何はともあれまずは使ってみましょう。

## インストール

Perl5.10以降の環境があれば以下のコマンド一発でインストールが完了します。

    % cpanm Riji

上記の操作を行うと、`riji`というコマンドがインストールされます。以降このコマンドを使ってBlogの操作を行います。

## セットアップ

適当な空のディレクトリを作り、その中で以下のコマンドを実行すると雛形が作られ、gitのリポジトリ作成、コミットまで自動で行われます。

    % riji setup

この状態でディレクトリを見ると以下のようになっていると思います。

    % tree
    .
    |-- README.md
    |-- article
    |   |-- archives.md
    |   |-- entry
    |   |   `-- sample.md
    |   `-- index.md
    |-- riji.yml
    `-- share
        `-- tmpl
                |-- base.tx
                |-- default.tx
                |-- entry.tx
                |-- index.tx
                `-- tag.tx

## ディレクトリ構成

### riji.yml

設定ファイルです

### article/

コンテンツ用のmdファイルを配置します。mdファイルを作るとそれに対応したURLでアクセス可能になります。

article直下のmdファイルはデフォルトで share/tmpl/default.tx がテンプレートに使われます。indexのみ例外でindex.txがテンプレートで使われるようになっています。

### article/entry/

ブログエントリーのmdファイルを配置するディレクトリです。デフォルトでentry.txがテンプレートに使われます。

### share/tmpl/

テンプレートが配置されています。Text::Xslate形式です

### share/static/

静的ファイルを配置します。static/... でアクセス可能になります。

## 起動

何はともあれこの状態で一旦サーバーを起動してみましょう。Rijiには組込のサーバーが付属しており簡単に動作確認可能です。

    % riji server
    HTTP::Server::PSGI: Accepting connections at http://0:3650/

3650番ポートでサーバーが起動するので、http://localhost:3650 にアクセスしてみてください。以下の様に表示されればOKです。

![setup](<: '/static/001setup.png' | uri_for :>)

## riji setup --force

空じゃない既存のディレクトリに`riji setup`したい場合は`% riji setup --force`を指定して下さい。GitHub Pagesを使うときなどに便利です。

今回はここまでです。

## 次回の内容

次回は新たにblogの設定と記事の作成を行います。

[002. Blog設定と記事の作成](<: '/entry/002_edit.html' | uri_for :>)
