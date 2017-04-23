# IZANAMI

MovableType環境を自動で構築します  
localではvagrant upで開発環境を構築する事も可能です。

## 動作テスト

| OS | AWS | GCP | Azure | さくら |
|:---------|:----:|:----:|:----:|:----:|
| RHEL 7 | ◯ | ◯ | ◯  | - |
| CentOS 7 | ◯  | ◯  | ◯  | - |
| CentOS 6 | ◯  | ◯  | ◯  | - |

## 起動方法

ansible-playbook -s -i hosts site.yml -u SSHユーザ名 --private-key=~/SSHの鍵のパス -l 対象サーバ（無指定ならhosts内全て） --extra-vars="mysql_root_password=MySQLのrootパスワード"  

## 注意

MySQLではDBパスワードに必ず英数字大文字＆記号を１つ以上使用して下さい。ERRORになります。

