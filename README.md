データベースの状態Aと状態Bを比較して差分を一覧するツール

アプリケーションを画面上で操作したとき、データの変化を把握するのに便利かも

## 準備

### 1. `config/settings/` に接続したい環境をのymlファイルを追加

例(`config/settings/sample.yml`)
```
database:
  adapter: mysql2
  database: sample_development
  host: db
  username: root
  password: password
  port: 3306

ignore_tables:
  - ar_internal_metadata
  - schema_migrations

stamp_path: stamps
log_path: /home/vagrant/apps/sample/log/development.log
```

### ローカルで起動する場合

#### 2. `.env` に環境を設定

```
ENVIRONMENT=sample # config/settings/sample.ymlと同じ名前
LOG_FILE=/home/username/app/log/development.log # 設定するとログファイルの比較が出ます
```

#### 3. 起動
```
$ ./start.sh
```

### コンテナで起動する場合

#### 2. `.env` に環境名を追加

デフォルトではvagrantで構築したVM(CentOS)を想定
実行環境に合わせて `/etc/passwd` などを参考に .envを設定する

```
CONTAINER_USER=YOUR_NAME
CONTAINER_USER_ID=YOUR_UID
CONTAINER_GROUP=GROUP_NAME
CONTAINER_GROUP_ID=YOUR_GID
ENVIRONMENT=sample           # config/settings/sample.ymlと同じ名前

# 接続先アプリのログボリュームを指定
EXTERNEL_LOG_VOLUME=external_app_log
# ログのボリュームは/tmpにマウントします
LOG_FILE=/tmp/development.log
```

#### 3. ビルドと起動

```
$ docker-compose build --no-cache
$ docker-compose up -d
```

#### 別のネットワークにあるDBコンテナに接続

ネットワーク名を.envに設定
```
NETWORK=any_network
```

#### デフォルトポート(3333)を別のポートに変更

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

# 注意

「すべてのテーブル」の「すべてのレコード」をローカルに保存して突合します
最低限のseedデータで実装を追跡したいとき向けです
データがたくさん入ったDBでは使わないほうがいいです
