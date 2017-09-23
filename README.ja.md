IZANAMI
====

Use Ansible to provision a full-stack MovableType Server

## Description

本プロジェクトは本番稼働に耐える高速なPSGI起動のMovable TypeをAnsibleで自動構築するものです。  
リモートサーバだけではなくローカルのVagrant環境も構築可能です。  
OSの初期セットアップからSSL証明書の取得、sshユーザの追加まで全て自動で構築されます。  
また、セキュリティにもある程度対策をしています。  

ライブラリなどを常に最新の環境にすることを優先しているためVagrantのBOXなどは用意していません。  
このため初回起動までに20分程度の時間がかかる事が予想されます。  

## Introduction

* MovableType5.2以降対応(MTOS含む)、PSGIもしくはCGI起動
* Perl5.18.2
* PHP(option)7.0
* Nginx
    * DynamicPublishingには非対応
* Apache
    * CentOS6は2.2系
    * CentOS7は2.4系
* MySQL5.7
* supervisord
* Let'sEncrypt
    * SSL証明書を自動取得可能です
    * Vagrant環境では非対応です

## Requirement

playbookを実行するためにはansible2.2以降が必要です  
  
### 各クラウドでのテスト結果 
| OS | AWS | GCP | Azure | sakura | vagrant |
|:---------|:----:|:----:|:----:|:----:|:----:|
| Amazon Linux | OK | - | - | - | - | - |
| RHEL 7 | OK | OK | OK | - | - | - |
| CentOS 7 | OK | OK | OK | - | OK |
| CentOS 6 | OK | OK | OK | - | - |

## Install

```bash
$ brew install ansible
$ git clone git@github.com:izanami-team/IZANAMI.git
```

## Usage

* Ansibleをインストールします。（2.2及び2.3で動作確認をしています)
    * Windows環境でのプロビジョニングは未テストです
    * 参考URL：http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-pip
* プロビジョニング元になるサーバ（もしくはローカルPC）に本プロジェクトをcloneします
* IZANAMIディレクトリにカレントディレクトリを移動します
* Movable Type(MTOS)の本体ファイルをroles/movabletype/files/以下に設置します
* プラグインを使用する場合は以下のように設置してください
    * roles/movabletype/files/mt-plugins/以下にプラグイン本体のファイルを設置
    * roles/movabletype/files/mt-static/以下に静的ファイルを設置
* Let'sEncrypt以外のSSL証明書を利用する場合は以下の場所に証明書を設置してください
    * Nginxを利用する場合　roles/nginx/ssl/
    * Apacheを利用する場合　roles/httpd/ssl/
* 以下のコマンドでサーバに接続するSSHユーザの公開鍵認証用のファイルを作成し、roles/sshd/files/public_keys/以下に設置します（.pub拡張子は削除し、ファイル名はSSHユーザ名と同一にします）
```bash
$ ssh-keygen -t rsa -b 4096
```
* 以下のコマンドでパスフレーズをハッシュ化し、メモしておきます(後述するymlファイルに記載します）
```bash
$ openssl passwd -1 '上記で入力したパスフレーズを指定'
```
* host_varsの中にあるサンプルの設定ファイルをコピーし、今回作成するサーバのホスト名.ymlとして保存します
    * vagrantの場合は192.168.33.99.ymlを直接修正します
* ymlファイルの中身を必要に応じて変更します。
* hostsファイルのdevelopment,staging,productionのいずれかのグループに今回作成するサーバのホスト名を設定します。（vagrantの場合は必要ありません）

### ymlファイルの編集方法

以下のようにymlファイルを設定することでプロビジョニング対象のサーバを細かく設定する事が可能です  
なお、利用しない項目は#でコメントアウトできます

```yaml
server_hostname:  "サーバのhostnameになります。通常はドメイン名を設定するとよいでしょう"
root_email: "ここに設定されたメールアドレスに対してlogwatchなどのメールが配信されます"
letsencrypt: letsencryptをインストールするのかTrue/Falseで設定します。無料でSSLを利用したい場合はTrueにしてください
denyhosts: サーバへのSSHアクセスに対して接続元IPアドレス制限が掛けられない場合にセキュリティを向上させます。通常はTrueで問題ありません。
php: サーバをapacheにした場合にmod_phpをインスト―ルします。DynamicPublishingなどを利用する場合はTrueにしてください。サーバをセキュアにする場合はFalseが良いでしょう
nginx: httpサーバをnginxにする場合はTrueにします。apacheを利用する場合はFalseを指定してください。なお.htaccessは利用できません。
apache: httpサーバapacheにする場合はTrueにします。nginxを利用する場合はFalseを指定してください。どちらかのみ有効です。
owner: "修正の必要はありません"
mt:
  file: MovableTypeの本体ファイル名を記載します
  ver: MovableTypeの本体ファイル名の解凍後のディレクトリ名を設定します
  psgi: サーバをPSGIで起動する場合はTrueにします。通常はTrueにします
  config: #以下の項目は複数指定可能です
    - {name: 'mt-configで追加設定する項目名を指定してください', value: '設定値を指定してください'}
  plugins: #以下の項目は複数指定可能です
    - 利用するプラグイン名を設定します
  db:
    name: MySQLのDB名を指定します。事前にDBを作成する必要はありません
    user: MySQLのユーザ名を指定します。事前にユーザを作成する必要はありません
    passwd: 'MySQLのパスワードを指定します。大文字小文字と記号の入った英数字を指定してください。最低8文字以上です'
    server: MySQLサーバのIPアドレスを指定してください。通常はlocalhostで問題ありません
  basic: #Basic認証を使用しない場合はここから３行を#でコメントアウトしてください 
    user: mtへのアクセスにBasic認証をかける場合にユーザ名を指定します
    passwd: Basic認証のパスワードを指定します
vhosts: #以下の項目は複数指定可能です
  - name: 構築するサーバのドメイン名を指定します
    letsencrypt: Let'sencryptでSSLを取得する場合はTrueを指定します
    ssl:
      use: Trueの場合にはroles/nginx/ssl/以下もしくはroles/httpd/ssl/以下の証明書のファイルをサーバに転送します
      only: True
      crt: 独自証明書の場合に証明書ファイル名を指定します
      key: 独自証明書の場合に鍵ファイル名を指定します
      ca_crt: 独自証明書の場合に中間証明書ファイル名を指定します
    email: "Let'sEncryptを使用する場合に有効期限の通知を行うメールアドレスを指定します"
wheel_users: #以下の項目は複数指定可能です
  - { name: sudo可能なSSHユーザ名, password: "パスフレーズをハッシュ化したものを記載" }
ssh_users:
  - { name: SSHユーザ名, password: "パスフレーズをハッシュ化したものを記載" }
sftp_users:
  - { name: SFTPのみ可能なユーザ名, password: "パスフレーズをハッシュ化したものを記載" }
```

### Vagrant

```bash
$ vagrant up
```

### remote server

```bash
$ ansible-playbook -s -i hosts site.yml -u "サーバ構築用のSSHユーザ" --private-key="鍵認証用の秘密鍵ファイルを指定" -l "hostsファイルに設定したサーバ名を指定" --extra-vars="mysql_root_password="mysqlのrootパスワードを指定（任意の英数字及び記号、大文字小文字が必須）""
```

### example

```bash
$ ansible-playbook -s -i hosts site.yml -u ec2-user --private-key=~/.ssh/id_rsa -l mt.example.com --extra-vars="mysql_root_password="@Passwd123""
```

### How to Use

* MTへのアクセス
    * リモートサーバ http[s]://fqdn/mt/mt.cgi
    * Vagrant http://movabletype.local/mt/mt.cgi
* ドキュメントルート
    * リモートサーバ /var/www/vhosts/fqdn/htdocs
    * Vagrant /var/www/vhosts/movabletype.local/htdocs
* Vagrantで起動した場合のアクセス用ドメイン
    * movabletype.local (hostsが必要です 192.168.33.99)
* MTの再起動
    * システムメニューのPSGIリスタートで再起動してください

## Licence

[MIT](https://github.com/tcnksm/tool/blob/master/LICENCE)

## Author

[onagatani](https://github.com/onagatani)
