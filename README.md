# IZANAMI

MovableType環境を自動で構築します  
localではvagrant upで開発環境を構築する事も可能です。

## 動作テスト

| OS | AWS | GCP | Azure | さくら | local |
|:---------|:----:|:----:|:----:|:----:|:----:|
| RHEL 7 | ◯ | ◯ | ◯  | - | - | - | 
| CentOS 7 | ◯  | ◯  | ◯  | - | ◯  |
| CentOS 6 | ◯  | ◯  | ◯  | - | - |

## 準備

- roles/movabletype/files/にMT-6.3.2.zipなどのデプロイする本体を設置  
- hostsファイルに該当サーバ名を追記 
- host_vars内にサンプルを参考にサーバ名.ymlファイルを設置し、中身をカスタマイズする
- 起動コマンドを実行する

### 詳細

http://blog.onagatani.com/archives/izanami.html  

## 起動方法

ansible-playbook -s -i hosts site.yml -u SSHユーザ名 --private-key=~/SSHの鍵のパス -l 対象サーバ（無指定ならhosts内全て） --extra-vars="mysql_root_password=MySQLのrootパスワード"  

## 設定

- プラグイン
-- host_vars/サーバ名.yml 内のpluginsをコメントアウトし、必要なファイルを設置してください
--- roles/movabletype/mt-plugins/ここに設置したディレクトリなどがそのままplugins配下に設置されます
--- roles/movabletype/mt-static/ここに設置したディレクトリなどがそのままmt-static配下に設置されます
- MT
-- ドキュメントルート
--- /var/www/vhosts/movabletype.local/htdocs
- ドメイン
-- movabletype.local (hostsが必要です）
- Basic認証
-- MTディレクトリはデフォルトでBasic認証配下になりますが必要なければhost_vars/サーバ名.yml 内のBasicをコメントアウトしてください

## 注意

MySQLではDBパスワードに必ず英数字大文字＆記号を１つ以上使用して下さい。ERRORになります。


