IZANAMI
====

Use Ansible to provision a full-stack MovableType Server

## Description
  
This project is the project that is constructed Movable Type server that is tolerable to start PSGI at high speed by Ansible automatically.
It is availabe to construct local Vagrant enviornment as wel as remote server.  
Initial set up, SSL certificate requirement adn ssh users addition is all constructed automatically.
In addition, the project partly takes a measure about security.

The project doesn't prepare such Vagrant box because it gives priority to bring them up to date.
Therefore, it is expected that it takes about 20 minutes to initial set up.

## Introduction

* Support since MovableType 5.2, PSGI or starting CGI.
    * Supported MT7(NEW) 
* Perl5.18.2
* Nginx
    * Unsupported php-fpm (DynamicPublishing)
* Apache
    * CentOS6 is 2.2 series
    * CentOS7 is 2.4 series
    * PHP7.0 (Optional)
* MySQL5.7, 8.0 (Amazon Linux 2)
* supervisord
* Let'sEncrypt
    * Available for obtaining SSL certificate.
    * Unsupported Vagrant enviornment

## Requirement

* ansible2.2 or later
* Vagrant (Optional: Only Vagrant) 
   * vagrant-hostsupdater
* Virtualbox (Optional: Only Vagrant) 
  
### Supported OS
| OS | AWS | GCP | Azure | sakura | vagrant |
|:---------|:----:|:----:|:----:|:----:|:----:|
| Amazon Linux | OK | - | - | - | - | - |
| Amazon Linux 2 | OK | - | - | - | - | - |
| RHEL 7 | OK | OK | OK | - | - | - |
| CentOS 7 | OK | OK | OK | - | OK |
| CentOS 6 | OK | OK | OK | - | - |

## <a name="Install">Install

```bash
$ brew install ansible
$ git clone git@github.com:izanami-team/IZANAMI.git
$ cd IZANAMI
```

## Usage

### required only for Vagrant
* settle to set up [homebrew](https://brew.sh/ 'Homebrew') beforehand
    * you also need Xcode to install homebrew. You can install Xcode from App Store. 
* Install [Vagrant](https://www.vagrantup.com/ "Vagrant")
* Install [Virtualbox](https://www.virtualbox.org/ 'Virtualbox')
* Install Vagrant Plugin
```bash
$ vagrant plugin install vagrant-hostsupdater
```

### detailed procedure
* Install Ansible[Install](#Install)
    * haven't tested Provisioning at Windows environment yet.
        * http://docs.ansible.com/ansible/latest/intro_installation.html#latest-releases-via-pip
* Clone this project to server (or local PC) that will be original Provisioning.
* Move Current Directory to IZANAMI Directory.
* Establish Movable Type(MTOS) file to roles/movabletype/files/
* Please establieh below if you use Plugin.
    * Establish Plugin's file to roles/movabletype/files/mt-plugins/
    * Establish static file to roles/movabletype/files/mt-static/
* Please establish certificate below if you use SSLcertificate other than Let'sEncrypt'S certificate.
    * If you use Nginx roles/nginx/ssl/
    * If you use Apache roles/httpd/ssl/
* Create file for public key auathentication that is connected to below'S comand and establish roles/sshd/files/public_keys/（delete .pub filename extension and name file's name as same as SSH user）
```bash
$ ssh-keygen -t rsa -b 4096
```
* Hash pass phrase below's comand and take note (will write to ymlfile）
```bash
$ Openssl passwd -1 'assign pass phrase that input'
```
* Copy sample's setting file that is in host_vars and preserve as host's name "yml" that create this time.
    * revise 192.168.33.99.yml directly if that is vagrant
* Change yml file's content as necessary.
* Set up host's name that creates this time to any groups of development,staging,production at host file. (doesn't need if that is vagrant）

### How to revise yml file

You can set indetail server that is targeted provisioning by setting yml file below.  
you can comment out as # if you don't use.

```yaml
server_hostname:  "to be server's hostname. You should set dmain name normally"
root_email: "mail suh as logwatch is delivered to email address that you set"
letsencrypt: set at True/False whether you instal letsencrypt or not. Please set as True if you want to use SSL for free.
denyhosts: improve security if you can't limit IP address to SSH access to server. Normally, there is no problem to set as True.
php: install mod_php if you set server as apache. Please set as True if ou use DynamicPublishing. You should set as False if you set server as Cure.
nginx: Please set as True if you set httpserver as nginx. Please set as False if you use apache. You can't us htaccess.
apache: Please set as True if you set http server as apache. Please set as False if you use nginx. Only available either one.
owner: "Don't need to revise"
mt:
  file: write MovableType's file name
  ver: set Directory's name after unzipping MovableType's file name
  psgi: Please set as True if you start server with PSGI. Normally set as True
  config: #Available to choose more than one below's list
    - {name: 'mt-config choose list's name that will set late', please set value: ''}
  plugins: #available to choose more than one below's list
    - set Plugin's name
  db:
    name: Choose MySQL's DB name. Don't need to create DB beforehand.
    user: Choose MySQL's user name. Don't need to create user beforehand.
    passwd: 'set MySQL password.Use alphanumeric character with small and big letter. More than 8 letters.'
    server: Set MySQL server's IP adress. Normally, ther is no problem to set as localhost.
  basic: #Please comment out 3 sentences with begining # if you don't use Basic authentication. 
    user: Choose user name if set to access to mt with Basic authentication.
    passwd: set password of Basic authentication.
vhosts: #you can choose more than one below's list.
  - name: set domain's name that will construct server
    letsencrypt: Please set as True if you aquire SSl at Let'sencrypt
    ssl:
      use: Transfer certification file to roles/nginx/ssl/ or roles/httpd/ssl/ if that is True
      only: Please set as True every time you use True. It's alright to set as True when you use SSL
      crt: Choose certification file  if that is special certification
      key: Choose key file name if that is special certifivation
      ca_crt: Choose interval certification name if that is special certificcation
    email: Set mail address that send information about expiration date if you use "Let'sEncrypt"
wheel_users: #you can choose more than one below's list
  - { name: sudo available SSH user name, password: "write hashed pass phrase" }
ssh_users:
  - { name: SSH user name, password: "write hashed pass phrase" }
sftp_users:
  - { name: SFTP only available user name, password: "write hashed pass phrase" }
```

### Vagrant

```bash
$ vagrant up
```

### remote server
Please set each server's initial user like ec2-user if that is EC2  
```bash
$ ansible-playbook -s -i hosts site.yml -u "SSH user for constructing server" --private-key="set private key file for kry authentication" -l "set server name that set hosts file" --set extra-vars="mysql_root_password="mysql's root password（need big and small leter, english numbers and letters）""
```

### example

```bash
$ ansible-playbook -s -i hosts site.yml -u ec2-user --private-key=~/.ssh/id_rsa -l mt.example.com --extra-vars="mysql_root_password="@Passwd123""
```

### How to Use

* Access to MT
    * Remote server http[s]://fqdn/mt/mt.cgi
    * Vagrant http://movabletype.local/mt/mt.cgi
* Document root
    * remote server /var/www/vhosts/fqdn/htdocs
    * Vagrant /var/www/vhosts/movabletype.local/htdocs
* access domain for starting with Vagrant
    * http://movabletype.local
    * need to host setting for 192.168.33.99 if you haven't install vagrant-hostsupdater plugin yet
* restaring MT
    * restart with PSGI at system menu

## Licence

[MIT](https://github.com/izanami-team/IZANAMI/blob/master/LICENSE)

## Author

[onagatani](https://github.com/onagatani)
