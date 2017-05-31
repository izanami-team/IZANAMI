server_hostname:  "mt.examaple.com"
root_email: "alert@mt.example.com"
letsencrypt: True
denyhosts: True
php: True
nginx: False
apache: True
owner: "{% if apache | bool %}apache{% else %}nginx{% endif %}"
mt:
  file: MT-6.3.2.zip
  ver: MT-6.3.2
  psgi: True
  #config:
  #  - {name: 'AdminScript', value: 'mt.cgi'}
  #  - {name: 'ImageDriver', value: 'Imager'}
  plugins:
    - PageBute
    - PSGIRestart
  db:
    name: movabletype
    user: movabletype
    passwd: 'ABC@123456example'
    server: localhost
  #basic:
  #  user: example
  #  passwd: example
vhosts:
  - name: mt.example.com
    letsencrypt: True
    ssl:
      use: True
      only: True
    email: "alert@mt.example.com"
wheel_users:
  - { name: admin_user, password: "openssl passwd -1 'passwd'でhash化したものを記載" }
ssh_users:
  - { name: ssh_user,   password: "openssl passwd -1 'passwd'でhash化したものを記載" }
sftp_users:
  - { name: sftp_user,  password: "openssl passwd -1 'passwd'でhash化したものを記載" }

