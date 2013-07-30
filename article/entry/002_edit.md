# 002. Blog設定と記事の作成

さて、前回はRijiのセットアップを行いました。`riji`というコマンドを使ってBlogを操作することを覚えているかと思います。また前回作ったリポジトリが手元にあると思うので引き続き、Rijiを使っていきましょう。

## Blogの設定

リポジトリにはriji.ymlが作られていますが、これの中身は以下のようになっています。

    author:   'Your name'
    title:    "Your Blog Title"
    site_url: 'http://yourblog.example.com/'

完全に仮の初期設定なので、自分の環境にあわせて変更してみましょう。`site_url`は最終的にアップするサイトのURLに合わせてください。特に決まってないのであれば仮のままで大丈夫です。

変更した状態で`% riji server`を起動してBlogを確認してみて下さい。変更内容が反映されているでしょうか？反映されていればriji.ymlをコミットしましょう。これでBlogの設定は完了です。

余談ですが、設定ファイルはTOMLにしようかとも考えたのですが、日和ってYAMLにしました。今後TOMLに対応するかもしれません。

## Blog記事の作成

早速記事を作成してみましょう。…と言いたいところですが、まずはsampleのファイルは必要ないので消してしまいましょう。

    % git rm article/entry/sample.md
    % git commit -m "remove sample.md"

次に、記事を作成しましょう。article/entry/ 以下に配置されていて拡張子が.mdになっていればなんでも良いのですが、今回はstart.mdという名前にして編集してみましょう。

    % $EDITOR article/entry/start.md
    % cat article/entry/start.md
    # blog開設
    
    Rijiを使ってBlogを開設しました。

編集はMarkdown形式でおこないます。[Discount](http://www.pell.portland.or.us/~orc/Code/discount/)というMarkdownパーサーがデフォルトで使われます。github flavored markdownと比較的互換があると思います。

さて、編集を終えたら、例に因って記事をコミットしてください。それから`riji server`をたちあげて、http://localhost:3650/entry/start.html にアクセスしてみましょう。以下の様な画面が表示されていればOKです。

![edit](<: '/static/002edit.png' | uri_for :>)

## Blog記事の追加

さて、もう一つ記事を追加してみましょう。ただ、毎回.mdファイルの名前を考えるのは面倒です。そこで以下のコマンドを使いましょう。

    % riji new-entry

今日の日付をもとに、エントリーファイルが作られ、環境変数`$EDITOR`が正しく設定されて入ればエディタも起動します。それを適宜編集して保存してコミットしましょう。これで２つ目のエントリーが作られました。`riji server`を使って確認してみてください。

## Blog記事以外のコンテンツの追加

Blog記事ではないコンテンツをサイトに追加したい時もあるでしょう。例えば自身のプロフィールページなどです。

そういったコンテンツは article/ 直下に配置します。プロフィールであれば、article/profile.md と言った具合になるでしょうか。この場合だと、article/profile.htmlにアクセスするとプロフィールページを閲覧できるようになるはずです。

今回はここまでです。

## 次回の内容

これまでは`riji server`を使った手元での確認だけでしたが、次回は実際にBlogの書き出しを行います。

[003. Blogの書き出しと公開](<: '/entry/003_publish.html' | uri_for :>)
