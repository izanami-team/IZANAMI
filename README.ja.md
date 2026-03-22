IZANAMI
====

Ansibleを使用してMovable Typeサーバーをフルスタックで構築するPlaybookです。
Vagrantを利用したローカル開発環境の構築にも対応しています。

## 構成

| ミドルウェア | バージョン |
|---|---|
| Perl | 自動で最新安定版を検出・インストール |
| Webサーバー | Nginx または Apache 2.4（MPM Event） |
| PHP | 8.5（Remi経由、OPcache + JIT有効） |
| MySQL | 8.4 LTS |
| SSL | Let's Encrypt（任意） |
| PSGI | Starman |

## 対応OS

| OS | バージョン |
|---|---|
| Amazon Linux | 2023 (AL2023) |
| Red Hat Enterprise Linux | 9 / 10 |
| AlmaLinux | 9 / 10 |
| Rocky Linux | 9 / 10 |

## 必要環境

* Ansible 2.10 以降
* Vagrant（ローカル開発環境の場合）
    * Mac (Intel) : VirtualBox
    * Mac (Apple Silicon) : Parallels Desktop（「Pro」または「Business」エディション）
    * vagrant-hostmanager プラグイン
    * vagrant-parallels プラグイン（Parallels利用時）

## インストール

```bash
$ brew install ansible
$ git clone git@github.com:izanami-team/IZANAMI.git
$ cd IZANAMI
```

### Vagrant利用時の追加セットアップ

1. [Homebrew](https://brew.sh/ja/) をインストール（Xcodeが必要。App Storeから入手可能）
2. [Vagrant](https://www.vagrantup.com/) をインストール
3. Vagrantプラグインをインストール

```bash
$ vagrant plugin install vagrant-parallels
$ vagrant plugin install vagrant-hostmanager
```

## ディレクトリ構成

```
IZANAMI/
├── site.yml                    # メインPlaybook
├── Vagrantfile                 # Vagrant設定
├── local                       # ローカル用インベントリ
├── group_vars/
│   ├── all/
│   │   ├── general.yml         # 共通変数（チューニング含む）
│   │   └── vault.yml           # 機密情報（パスワード等）
│   └── vagrant/
│       └── general.yml         # Vagrant環境用変数
├── host_vars/
│   ├── 192.168.33.99.yml       # Vagrant VM用ホスト変数
│   └── example.com.yml         # 本番サーバー用ホスト変数（サンプル）
└── roles/
    ├── common/                 # 基本パッケージ、ロケール、タイムゾーン
    ├── mysqld/                 # MySQL 8.4 LTS
    ├── perl/                   # Perl（最新安定版自動検出）
    ├── php/                    # PHP 8.5 + OPcache + JIT
    ├── nginx/                  # Nginx
    ├── httpd/                  # Apache 2.4
    ├── movabletype/            # Movable Type デプロイ
    ├── ImageMagick/            # ImageMagick（ソースビルド）
    ├── letsencrypt/            # Let's Encrypt SSL証明書
    ├── postfix/                # メール送信設定
    ├── firewall/               # firewalld設定
    ├── sshd/                   # SSH強化設定
    ├── swap/                   # スワップ設定
    ├── aws/                    # AWS固有設定（AL2023用）
    └── restart/                # サービス起動・SELinux設定
```

## 使い方

### ローカル開発環境（Vagrant）

```bash
$ vagrant up
```

### リモートサーバーへのデプロイ

```bash
$ ansible-playbook -i hosts site.yml -u ec2-user --private-key=~/.ssh/private_key.pem -l servername
```

### 特定のロールのみ実行

```bash
# タグを指定して特定ロールのみ実行
$ ansible-playbook -i hosts site.yml --tags "perl,movabletype" -l servername
```

## 設定のカスタマイズ

### ホスト変数（host_vars）

各サーバーごとの設定は `host_vars/` に配置します。`host_vars/example.com.yml` をテンプレートとして利用してください。

#### 主要な設定項目

```yaml
server_hostname: "example-com"        # サーバーのホスト名
apache: True                          # Apache を使用する場合 True
nginx: False                          # Nginx を使用する場合 True（apacheと排他）
php: True                             # PHP をインストールする場合 True
ImageMagick: True                     # ImageMagick をインストールする場合 True

mt:
  file: MT-9.0.6.zip                  # MTのzipファイル名（roles/movabletype/files/ に配置）
  psgi: True                          # PSGI (Starman) を使用する場合 True
  config:                             # mt-config.cgi に追加する設定
    - {name: 'AdminScript', value: 'admin'}
    - {name: 'ImageDriver', value: "{% if ImageMagick | bool %}ImageMagick{% else %}Imager{% endif %}"}
  plugins:                            # インストールするプラグイン（roles/movabletype/files/mt-plugins/ に配置）
    - PSGIRestart
  db:
    name: movabletype                 # データベース名
    user: "{{ vault.mt.db.user }}"    # DBユーザー名
    password: "{{ vault.mt.db.password }}"
    server: localhost
  email: noreply@example.com          # MT管理者メールアドレス

vhosts:                               # バーチャルホスト設定（複数指定可能）
  - name: www.example.com
    letsencrypt: True                 # Let's Encrypt を使用する場合 True
    email: "ssl@example.com"          # Let's Encrypt の通知メールアドレス
    ssl:
      use: True                       # SSL を使用する場合 True
      only: True                      # HTTPS のみにリダイレクトする場合 True
```

### Movable Type のzipファイル配置

MTのzipファイルは以下に配置してください。展開後のフォルダ名は自動検出されます。

```
roles/movabletype/files/MT-9.0.6.zip
```

### パスワード等の機密情報

`group_vars/all/vault.yml` に記載します。本番運用時は `ansible-vault` で暗号化してください。

```bash
$ ansible-vault encrypt group_vars/all/vault.yml
```

### チューニング

`group_vars/all/general.yml` にデフォルトのチューニングパラメータが定義されています。
`host_vars` でサーバーごとにオーバーライドできます。

#### MySQL チューニング

```yaml
mysql_tuning:
  innodb_buffer_pool_size: "256M"     # 物理メモリの50-70%を推奨
  innodb_redo_log_capacity: "256M"
  innodb_flush_method: "O_DIRECT"
  innodb_flush_log_at_trx_commit: 2   # 1: 安全優先、2: 性能優先
  max_connections: 150
  max_allowed_packet: "64M"
  binlog: false                       # レプリケーション不要ならfalse
  mysqlx: false                       # X Protocol不要ならfalse
```

#### PHP チューニング

```yaml
php_tuning:
  opcache:
    memory_consumption: 256           # OPcacheメモリ（MB）
    jit: "tracing"                    # JITコンパイラ（PHP 8.5）
    jit_buffer_size: "128M"
    validate_timestamps: 1            # 本番では 0 にすると最速
    revalidate_freq: 60               # ファイル変更チェック間隔（秒）
  fpm:
    pm: "dynamic"                     # static: 最速（メモリ余裕時）、ondemand: 省メモリ
    max_children: 10
    max_requests: 500
```

### バーチャルホストの複数指定

Vagrantで複数ドメインを使用する場合、Vagrantfile の `hostmanager.aliases` を有効化してください。

```ruby
rocky9.hostmanager.aliases = %w(cms.example.com stg.example.com)
```

### Basic認証

本番環境（inventoryが `local` 以外）で自動的に有効になります。

```yaml
basic:
  auth: True
  path: /                            # 認証対象パス
  user: example
  passwd: passwd
```

### SSHユーザーの追加

`group_vars/all/vault.yml` でユーザーを定義します。

```yaml
vault:
  ssh:
    users:
      - { name: admin, group: "wheel", password: "secure_password" }
      - { name: user, password: "secure_password" }
```

### Postfix（メールリレー）

外部SMTPサーバー経由でメール送信する場合の設定です。

```yaml
postfix:
  relay: True
  smtp:
    from: "example.com"
    user: "smtp_user"
    password: "smtp_password"
    server: "smtp.example.com"
    port: "587"
```

## Movable Type へのアクセス

構築完了後、以下のURLでアクセスできます。

| 項目 | パス |
|---|---|
| 管理画面 | http://rocky9.local/mt/admin |
| 初期ユーザー | admin / password |
| ドキュメントルート | /var/www/vhosts/rocky9.local/htdocs |
| MT インストール先 | /var/www/movabletype |

## ロールの詳細

### common
OS共通の基本設定を行います。
- 開発ツール、必須パッケージのインストール
- EPEL / CRBリポジトリの有効化
- ロケール（ja_JP.UTF-8）、タイムゾーン（Asia/Tokyo）の設定
- ホスト名の設定
- 共有グループの作成

### perl
CPANから最新安定版のPerlバージョンを自動検出し、xbuildでインストールします。
- 偶数マイナーバージョン（安定版リリース）のみを対象
- DBI、DBD::mysql、Plack、Starman等のCPANモジュールを自動インストール

### mysqld
MySQL 8.4 LTSをインストールします。
- チューニングパラメータは `mysql_tuning` 変数で制御
- InnoDB最適化済み（O_DIRECT、redo log capacity等）

### php
PHP 8.5をRemiリポジトリからインストールします。
- OPcache + JITコンパイラ有効
- php-fpmのチューニングパラメータは `php_tuning` 変数で制御

### httpd
Apache 2.4をMPM Eventモードで構築します。
- 不要モジュールの無効化
- SSL利用時はHTTP/2有効、TLSv1.2/1.3対応、モダンCipherSuite
- セキュリティヘッダー設定済み（ServerTokens Prod、X-Frame-Options等）

### nginx
Nginxをリバースプロキシとして構築します。
- Starman（PSGI）へのプロキシ設定

### movabletype
Movable Typeをデプロイします。
- zipファイルの展開、フォルダ名の自動検出
- mt-config.cgi の生成
- shebangの自動書き換え
- systemdサービス（movabletype、run-periodic-tasks）の登録
- データベース・ユーザーの自動作成
- 初期セットアップの自動実行

## ライセンス

MIT
