データベースの状態Aと状態Bを比較して差分を一覧するツール

アプリケーションを画面上で操作したとき、データの変化を把握するのに便利かも

### 比較するDBを設定

 `config/setgings.yml` または `config/settings/development.yml` を接続したいDBの情報に変更

### ローカルで実行

```
$ ./start.sh
```

または

```
bundle exec ruby app.rb -o 0.0.0.0 -p 3333
```

### コンテナで実行

デフォルトではvagrantで構築したVM(CentOS)を想定してます
ユーザーやUIDが異なる場合は.envに以下を設定してください

```
CONTAINER_USER=YOUR_NAME
CONTAINER_USER_ID=YOUR_UID
```

**コンテナ起動**
```
$ docker-compose build --no-cache
$ docker-compose up -d
```


#### .env

ポートを開放していないコンテナのネットワークに接続したい場合
接続先のネットワークを.envに記載する

```
NETWORK=any_network
```

デフォルトポート(3333)を別のポートに変更したい場合

```
SINATRA_PORT=xxxx
```

### 使い方

`http://localhost:3333/` にアクセス

"ダンプ保存"を押すとDBダンプを保存
テキスト入れると名前がつけれる

"全部削除"を押すと保存したDBダンプを全部削除

比較したいダンプをラジオボタンの一覧から選択

"比較"を押すとなんか出る

### 注意

「すべてのテーブル」の「すべてのレコード」をローカルに保存して突合します
最低限のseedデータで実装を追跡したいとき向けです
データがたくさん入ったDBでは使わないほうがいいです
