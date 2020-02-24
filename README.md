# kakomon-manager-legacy
Git + CI で過去問をいい感じに管理するもの

## 何これ？

Google Driveと連携して使える過去問共有用ツール

## どうやって使うん？
1. まず、github上に上がってるレポジトリをローカル環境に複製しよう(ダウンロード)。

    - <#gitコマンドを使うたびにリモートレポジトリにアクセスするたびパスワードが必要でめんどくさい>の設定をした人 `  
        git clone git@github.com:satackey/test-preps.git`
    - そうではない人  
        `git clone https://github.com/satackey/test-preps.git`
### スキャンした画像のアップロード
1. `git checkout master` (masterにいく)

1. `git pull` (masterを最新にする)

1. `git checkout -b 'branch名'` (branchを切る)

1. scannedにpngかpdfかjpg形式の過去問たちをぶち込む
   拡張子は`.jpg`にすること。`.jpeg`は**だめ**！！！

1. `git add .`

1. `git commit -m "作業の内容等を書こう"` (commit)

1. `git push` (ファイルをあげる)

### アップロードされた画像の分類 (CSVの記入)
1. 
    - 以前にブランチをローカルで開いたことがあるとき
        - `git checkout ブランチの名前`
        - `git pull`
    - 初めてブランチを開くとき
        - `git fetch`
        - `git checkout -b ブランチの名前 origin/ブランチの名前`


1. そしてmetadatasのcsvファイルを編集するだけ！簡単でしょ？

1. `git add .`

1. `git commit -m "作業の内容等を書こう"` (commit)

1. `git push` (ファイルをあげる)

### プルリクエスト
1. Githubでpull request！

1. 他の誰かがApprove(承認)してくれるのを待とう！修正の指摘があれば訂正しよう！！

1. Approveされたらマージできるようになっているので、`Merge pull request`→`Confirm merge`をしてマージしよう！

## csvの書き方
1. subj 


   科目名


1. tool_type 


   そのファイルの目的


   "勉強用", "テスト"とか。


1. period 


   時期


   "前期中間", "前期定期", "後期中間", "後期定期"とか。


1. year 


   何年度なのかとか


   **年度**なので2月の過去問を追加するときは注意する。


1. content_type 


   そのファイルの役割みたいなもの



   tool_typeによって指定できるものが変わる。


tooltype | "テスト" | "勉強用"
:---: | --- | --- 
-- | "問題" | "ノート" 
-- | "解答なし答案用紙" |  "まとめ"
-- | "学生解答" |  "対策プリント"
-- | "模範解答"


1. author
    - 過去問のとき  
        テスト担当の教員名 or プリントを作成した教員名。
    - 勉強用のノートやまとめのとき  
        テスト担当の教員名 or プリントを作成した教員名 **+ ノート・まとめを書いた人が識別できる名前**
        (本名を上げるのはアレなので……重複しなければなんでもよいが、わかりやすい方が良い。


1. image_index 連番号(順番判別用の名称末尾につく連番の番号)  
    この順番でPDFが作成される


1. included_pages_num (そのファイル単体での)総ページ数？っぽい。


1. fix_text 直してーってお願いする内容とか
  `重複`にしてコミットすると、自動的に削除されたコミットが作成される。


# Makefileの使い方(ほぼgithub上で自動化されてるので使う機会はほぼないです
- generate 


   pdf作成


   integrated_pdfフォルダが作成される。


- check 


   確認


   csvファイルを確認しエラーを出力。

- assort 


   ソート


   csvを参考にソート。

- commit-assorted


   assort実行後にソート変更をコミットするためのもの(assortは実行されない。

- docker


   ~~皆大好き~~dockerを使って環境構築pythonを必要なモジュールを用意した状態で提供する。

### 以下から下は個人環境で使用~~できないと思います~~しないでください
- gen-upload


   作成したファイル達をgoogleドライブに共有する準備。


   integrated_pdfフォルダがuploadフォルダへとコピーされる。

- upload-to-googledrive


   rsyncを用いてgoogle driveに共有。

### gitコマンドを使うたびに(リモートレポジトリにアクセスするたび)パスワードが必要でめんどくさい？
1. `ssh-keygen -t ed25519`のあと三回エンター

1. githubの自分の設定ページからSSH and GPG keysを選択してid_ed25519.pubの内容をコピーペーストしよう

1. `ssh -T git@github.com`で確認

### そもそもgitの設定ができてない？
1. `git config --global user.email "メールアドレス"`
    本来は自分のメールアドレスを書くが、この設定を公開リポジトリでも使用するとメールアドレスが世界中に公開されてしまう。
    <https://github.com/settings/emails> の `Primary email address`にある `12345678+username@users.noreply.github.com`のようなアドレスを設定しておくとよい。

1. `git config --global user.name "githubで使ってる名前"

### vscodeの設定も教えてよ（前提としてgitの設定が終わっているものとしています）
1. git拡張を入れておくと便利(@category:"scm providers" で拡張を検索)

1. フォルダを開く
- ショートカットを使うと、コントロールキーを押したままｋを押してそのあとコントロールキーを押したままoを押す(Ctrl+K Ctrl+O)

1. gitレポジトリのフォルダを選択

1. 自動的になんかいろいろしてくれる

1. 左下にあるブランチの状態を表示してるステータスを押してブランチを切る	

1. 進捗をだす

1. 左のおなじみgitマークをクリック

1. 変更したファイルにカーソルを合わせて＋やーマークをクリックしてステージに適用

1. チェックマークを押して変更をコミット

1. 一定のコミットが用意できたらpush!!
