# 003. Blogの書き出しと公開

Rijiは`riji server`で動的に運用してもいいのですが、静的配信にも対応しています。静的配信できた方が何かと便利ですね。

前回勿体つけて「Blogの書き出し」などといいましたが、Blogの書き出しは実に簡単で以下のコマンドを実行するだけです。

    % riji publish

上手く行けばblog/というディレクトリが作られ、その中にサイト一式が格納されているはずです。atom.xmlも入っていますね。

もしかしたら、wgetが無いことを怒られるかもしれません。その場合はwgetをインストールしてください。なんでwgetを使ってるかは実装を見て察してください。

あとは、blog/ディレクトリをどこかにアップロードするだけです。せっかくgitリポジトリになっているので、そのままGitHub Pages等にpushしてしまっても良いんじゃないかと思います。

## publishディレクトリの変更

上のようにデフォルトでは blog/ にサイトが作られますが、これを変更したいという要望もあるかと思います。その場合は、riji.ymlにpublish_dirというキーを追加して設定を書いてください。'.' に設定したらカレントディレクトリにドバっと作られます。

## GitHub Pagesについて

githubで"[username].github.io"というリポジトリを作成するとそれを自分のサイトとして運用することが可能になります。git pushすればすぐにサイトに反映されるので非常に楽ちんです。Rijiで作成したblogの配信先として検討しても良いと思います。

## Githubリポジトリへのページ設置について

[username].github.ioに関してはよく知られるところですが、自分のリポジトリで`gh-pages`というブランチを作るとそれもGitHub Pagesとして運用可能であることはご存知でしょうか？これで作られたサイトは http://[username].github.io/[repositoryname]/ というURLでアクセスが可能になります。

具体的には以下の手順で作成します。

=親のないブランチを作成=
    `% git checkout --orphan gh-pages`
=ファイルを全て削除=
    `% git rm -rf *`
=空じゃないディレクトリにセットアップするので--forceをつけてriji setup=
    `% riji setup --force`
=追随するブランチがmasterブランチではないので、riji.ymlに追随ブランチの設定をする=
    `% echo 'branch: gh-pages' >> riji.yml`
=pushする=
    `% git push --set-upstream origin gh-pages`

あとはこれまで学んできたようにRijiを運用するだけです。

今回はここまでです。

## 次回の内容

とりあえず、公開するところまではできましたが、簡素でバランスの悪いデフォルトのデザインの調整等がしたくなってきている頃かと思います。
次回は、静的ファイルの配信について説明します。

[004. 静的ファイルの配置と配信](<: '/entry/004_static.html' | uri_for :>)