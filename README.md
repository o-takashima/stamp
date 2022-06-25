データベースの状態Aと状態Bを比較して差分を一覧するツール

アプリケーションを画面上で操作したとき、データの変化を把握するのに便利かも

## 準備

### 1. `config/settings/` に接続したい環境のymlファイルを追加

例(`config/settings/sample.yml`)
```
database:
  adapter: mysql2
  database: sample_development
  host: host.docker.internal
  username: root
  password: password
  port: 3306

ignore_tables:
  - ar_internal_metadata
  - schema_migrations

stamp_path: stamps
repository: https://github.com/<sample_corp>/sample # リポジトリがある場合、ログにリンクを張る
branch: develop
```

### 2. 外部ボリューム作成

`docker volume create log_data` を実行

### 3. 追跡したいサービスのログをlog_dataにマウント

```
services:
  app:
    volumes:
      - log_data:/api/log
volumes:
  log_data:
    external: true
```
docker-compose.override.yml とか使うと良さそう


### ローカルで起動する

非推奨。というか未検証。多分動かない
少なくともログは出ない

#### 2. `.env` に環境を設定

```
ENVIRONMENT=sample # config/settings/sample.ymlと同じ名前
```

#### 3. 起動
```
$ ./start.sh
```

### コンテナで起動する

#### 2. `.env` に環境名を追加

実行環境に合わせて `.env` を設定

```
CONTAINER_USER=YOUR_NAME
CONTAINER_USER_ID=YOUR_UID
CONTAINER_GROUP=GROUP_NAME
CONTAINER_GROUP_ID=YOUR_GID
ENVIRONMENT=sample           # config/settings/sample.ymlと同じ名前
```

#### 3. ビルドと起動
```
$ docker-compose build --no-cache
$ docker-compose up -d
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

「すべてのテーブル」の「すべてのレコード」をダンプして突合します
最低限のseedデータで実装を追跡したいとき向けです
データがたくさん入ったDBでは使わないほうがいいです
