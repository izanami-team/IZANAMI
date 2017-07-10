# IZANAMI

Construct the MovableType environment with ansible
Also supports vagrant

## environment

| OS | AWS | GCP | Azure | sakura | vagrant |
|:---------|:----:|:----:|:----:|:----:|:----:|
| Amazon Linux | OK | - | - | - | - | - |
| RHEL 7 | OK | OK | OK | - | - | - |
| CentOS 7 | OK | OK | OK | - | OK |
| CentOS 6 | OK | OK | OK | - | - |

## configuration

- copy MT-6.3.x.zip path to roles/movabletype/files/
- add server name in hosts file
- place server name.yml file in host_vars
- customize name.yml

### details

http://blog.onagatani.com/archives/izanami.html

## provisioning

### vagrant

`vagrrant up`

### server
`ansible-playbook -s -i hosts site.yml -u "ssh user name" --private-key="path to private key file" -l "target server (all in hosts if not specified)" --extra-vars="mysql_root_password="mysql root password""`

## settings

- plugin
    - add necessary plugin to plugins in server name.yml
        - set plugin in roles/movabletype/files/mt-plugins
        - set mt-static in roles/movabletype/files/mt-mt-static
- apache
    - document root  
    - /var/www/vhosts/movabletype.local/htdocs
- domain
    - movabletype.local (hosts 192.168.33.99)

## caution

alphanumeric capital letters & symbols for DB password in MySQL
