IZANAMI
====

AnsibleでVagrantやVMサーバにMovable Typeのサーバを構築します  
※  MovableTypeをOFFにすることでWEBサーバやPHP用のサーバを構築する事も可能です

## Description

本プロジェクトは本番稼働に耐える高速なPSGI起動のMovable TypeサーバをAnsibleで自動構築するものです。  
リモートサーバだけではなくローカルに本番同等のVagrant環境も構築出来ます。  
OSの初期セットアップからSSL証明書の取得、sshユーザの追加まで全て自動で構築されます。  
また、セキュリティにもある程度対策をしています。

## Introduction

* MovableType5.2以降対応(MTOS含む)、PSGIもしくはCGI起動
  * MT7で動作確認しています
* Perl5.30
* Nginx
    * DynamicPublishingには非対応
* Apache2.4
* ImageMagick (optional)
    * MTの画像ライブラリはImagerを利用します。またダイナミックパブリッシングはGDで動作するため通常は不要ですが、PHPから利用する場合を想定しplaybookではサポートしています 
* PHP(optional)
   * AmazonLinux2 : 7.3
   * RHEL7-8/CentOS7-8 : 7.4 (Remi) 
* MySQL
   * AmazonLinux2/RHEL7/CentOS7 : 5.7
   * RHEL8/CentOS8 : 8
* supervisord
   * MTの死活監視を行います
* Let'sEncrypt
    * SSL証明書を自動取得します
    * Vagrant環境では非対応です

## Requirement

* ansible2.3 以降
   * Mac Ansible2.9で確認しています
* Vagrant (ローカルに構築する場合) 
   * vagrant-hostmanager
   * vagrant-vbguest
* Virtualbox (ローカルに構築する場合) 
  
### 各クラウドでの対応OS 
| OS | AWS | GCP | Azure | sakura | vagrant |
|:---------|:----:|:----:|:----:|:----:|:----:|
| Amazon Linux 2 | OK | TBD | TBD | TBD | OK |
| RHEL 8 | OK | TBD | TBD | TBD | - |
| RHEL 7 | OK | TBD | TBD | TBD | - |
| CentOS 8 | OK | TBD | TBD | TBD | OK |
| CentOS 7 | OK | TBD | TBD | TBD | OK |

* AMI
   * RHEL : 公式アカウント文字列「309956199498 」の7,8を利用
   * CentOS : https://wiki.centos.org/Cloud/AWS 公式のwikiから7,8を利用
* CPUアーキテクチャ
   * サポート：x86_64
   * 未定：ARM64 (AWS Gravitonでは動作致しません)

## <a name="Install">Install

```bash
$ brew install ansible
$ git clone git@github.com:izanami-team/IZANAMI.git
$ cd IZANAMI
```

## Usage

### required only for Vagrant
* 事前に[homebrew](https://brew.sh/index_ja.html 'Homebrew')のセットアップを済ませます
    * homebrewのインストールにはXcodeも必要になります。XcodeはApp Storeからインストールできます
* [Vagrant](https://www.vagrantup.com/ "Vagrant")をインストールします
* [Virtualbox](https://www.virtualbox.org/ 'Virtualbox')をインストールします
* Vagrantプラグインをインストールします
```bash
$ vagrant plugin install vagrant-hostmanager
$ vagrant plugin install vagrant-vbguest
```

### detailed procedure
* Ansibleをインストールします。[Install](#Install)
    * Windows環境でのプロビジョニングは未テストです
    * 参考URL：http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-pip
* プロビジョニング元になるサーバ（もしくはローカルPC）に本プロジェクトをcloneします
* IZANAMIディレクトリにカレントディレクトリを移動します
* Movable Typeの本体ファイルをroles/movabletype/files/以下に設置します
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
    * vagrantの場合は192.168.33.101.ymlを直接修正します
* ymlファイルの中身を必要に応じて変更します。
* hostsファイルのdevelopment,staging,productionのいずれかのグループに今回作成するサーバのホスト名を設定します。（vagrantの場合は必要ありません）

### ymlファイルの編集方法

以下のようにymlファイルを設定することでプロビジョニング対象のサーバを細かく設定する事が可能です  
なお、利用しない項目は#でコメントアウトできます

```yaml
server_hostname:  "サーバのhostnameになります。通常はドメイン名を設定するとよいでしょう"
root_email: "ここに設定されたメールアドレスに対してlogwatchなどのメールが配信されます"
letsencrypt: letsencryptをインストールするのかTrue/Falseで設定します。無料でSSLを利用したい場合はTrueにしてください
php: サーバをapacheにした場合にmod_php/php-fpmをインスト―ルします。DynamicPublishingなどを利用する場合はTrueにしてください。サーバをセキュアにする場合はFalseが良いでしょう
ImageMagick: PHPアプリケーションから利用する場合はTrueにして下さい。通常必要ありません。
nginx: httpサーバをnginxにする場合はTrueにします。なお.htaccessは利用できません。
apache: httpサーバapacheにする場合はTrueにします。どちらかのみ有効です。
owner: "修正の必要はありません"
basic:
  auth: Basic認証を利用する場合はTrueにします
  path: 認証を必要とするパスを設定します。「/」を設定するとサイト全てを認証下にします
  user: ユーザ名
  passwd: パスワード
mt:
  require_ip:
    - MTをIP制限します。利用する場合はIPを記載します。(- で複数指定可能です）
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
vhosts: #以下の項目は複数指定可能です
  - name: 構築するサーバのドメイン名を指定します
    letsencrypt: Let'sencryptでSSLを取得する場合はTrueを指定します
    ssl:
      use: Trueの場合にはroles/nginx/ssl/以下もしくはroles/httpd/ssl/以下の証明書のファイルをサーバに転送します
      only: 常時SSLを使用する場合はTrueを指定します。SSLを使用する場合はTrueで良いでしょう
      crt: 独自証明書の場合に証明書ファイル名を指定します
      key: 独自証明書の場合に鍵ファイル名を指定します
      ca_crt: 独自証明書の場合に中間証明書ファイル名を指定します
    email: "Let'sEncryptを使用する場合に有効期限の通知を行うメールアドレスを指定します"
postfix:
  relay: SESやSendFridを利用してメールをリレーする場合にTrueを設定します
  smtp:
    from: メールのFromドメインを指定します
    user: リレーするアカウントのACCESSKEYを指定します
    pass: リレーするアカウントのACCESS_SECRETを指定します
    server:リレーするアカウントのSMTP_SERVERを指定します
    port: リレーするサーバのポートを指定します 例：587
ssh_users: 追加するSSHユーザを以下のように記載します
  - { name: wheel_user1,    group: "wheel",                password: "hash" }
  - { name: ssh_user1,      group: "{{ shared_group }}",   password: "hash" }  # sshを許可するユーザ
  - { name: sftponly_user1, group: "{{ sftponly_group }}", password: "hash" }  #  SFTPのみ許可するユーザー
```

### Vagrant

```bash
$ vagrant up
```
失敗したらエラー内容を修正して再実行
```bash
$ vagrant provision
```

### remote server
EC2ならec-userのように各サーバの初期ユーザを指定してください  
```bash
$ ansible-playbook -s -i hosts site.yml -u "サーバ構築用のSSHユーザ" --private-key="鍵認証用の秘密鍵ファイルを指定" -l "hostsファイルに設定したサーバ名またはstagingなどのグループを指定" --extra-vars="mysql_root_password="mysqlのrootパスワードを指定（任意の英数字及び記号、大文字小文字が必須）""
```

### example

```bash
$ ansible-playbook -s -i hosts site.yml -u ec2-user --private-key=~/.ssh/id_rsa -l mt.example.com --extra-vars="mysql_root_password="@Passwd123""
```

### How to Use

* MTへのアクセス
    * リモートサーバ http[s]://fqdn/mt/admin
    * Vagrant http://amzn2.local/mt/admin (ドメインは変更できます）
* ドキュメントルート
    * リモートサーバ /var/www/vhosts/fqdn/htdocs
    * Vagrant /var/www/vhosts/amzn2.local/htdocs
* Vagrantで起動した場合のアクセス用ドメイン
    * http://amzn2.local
    * vagrant-hostmanager pluginをインストールしていない場合は192.168.33.101に対してhosts設定が必要です。
    * VagrantではIZANAMIカレントディレクトリ内のsharedディレクトリが Vagrant環境の/var/www/にマウントされています
* MTの再起動
    * システムメニューのPSGIリスタートで再起動してください
    * 再起動コマンド
        * $ sudo supervisorctl restart movabletype 
* mysqlへのログイン
    * rootへスイッチしてから以下のコマンドを実行します
        * mysql
* vagrant upが失敗する
    * host_vars/xxx.ymlの設定内容に誤りがあるか、roles/movabletype/files/以下にMT-xx.zipファイルを設置しない可能性があります。確認ください。

## Licence

[MIT](https://github.com/izanami-team/IZANAMI/blob/master/LICENSE)

## Author

[onagatani](https://github.com/onagatani)
