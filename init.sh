#!/bin/bash
#https://www.linode.com/docs/getting-started/
#https://www.linode.com/docs/security/securing-your-server/
#https://www.linode.com/docs/applications/remote-desktop/remote-desktop-using-apache-guacamole-on-docker/
#https://www.dofus.com/fr/forum/1115-bugs/2289966-jouer-linux-debian-9


##-- VARS
HOSTNAME="flancoco"
DOMAIN=""
USER="jeremi"
  USER_PASS="xxxxxx"
  USER_DB_PASS="${USER_PASS}"
  ROOT_DB_PASS="xxxxxx"

##-- Set HOSTNAME
echo "${HOSTNAME}" > /etc/hostname
hostname -F /etc/hostname
echo -e "$(hostname -i) \t $HOSTNAME" >> /etc/hosts

##-- Set TimeZone
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

##-- Set USER
#> TODO: nopass sudo
useradd -m -s /bin/bash ${USER}
echo -e "${USER_PASS}\n{USER_PASS}" | passwd ${USER}
unset USER_PASS
adduser ${USER} sudo
sed -i -e "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
service ssh restart

##-- Install PKG
#> TODO: add depot contrib nonfree
apt update && apt upgrade -y
apt install -y fail2ban net-tools

#-- Install Docker
apt remove -y docker docker-engine docker.io
apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update && apt install -y docker-ce
usermod -aG docker $USER

#-- Config Guacamole
docker pull guacamole/guacamole
docker pull guacamole/guacd
docker pull mysql/mysql-server
 
#-- Install Docker
apt remove docker docker-engine docker.io
apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt update && apt install -y docker-ce
usermod -aG docker $USER

#-- Config Guacamole
docker pull guacamole/guacamole
docker pull guacamole/guacd
docker pull mysql/mysql-server

#-- init DB
docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > initdb.sql
docker run --name guacmysql -e MYSQL_ROOT_PASSWORD="${ROOT_DB_PASS}" -e MYSQL_ONETIME_PASSWORD=yes -d mysql/mysql-server
docker cp initdb.sql guacmysql:/guac_db.sql
docker exec -it guacmysql bash
> mysql -u root -p
>> ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_DB_PASS}';
>> CREATE USER '${USER}'@'%' IDENTIFIED BY '${USER_DB_PASS}';
>> CREATE DATABASE guacamole_db;
>> GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO '${USER}'@'%';
>> FLUSH PRIVILEGES;
>> quit

> cat guac_db.sql | mysql -u root -p guacamole_db
> exit

unset USER_DB_PASS ROOT_DB_PASS

#-- App guacamole
docker run --name guacd -d guacamole/guacd
docker run --name guacamole --link guacd:guacd --link guacmysql:mysql -e MYSQL_DATABASE='guacamole_db' -e MYSQL_USER='${USER}' -e MYSQL_PASSWORD='${USER_DB_PASS}' -d -p 127.0.0.1:8080:8080 guacamole/guacamole
docker ps

#-- Proxy NGINX
#cat > $HOME/.config_nginx << "EOF"
#server {
# listen 80;
# server_name flancoco;
# 
# location / {
#  proxy_pass http://localhost:8080/guacamole;
# }
#}
#EOF
#docker pull nginx
#docker run --name nginx -d -v $HOME/.config_nginx:/etc/nginx/conf.d/nginx.conf nginx

#-- proxy APACHE
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
vim /etc/apache2/sites-enabled/000-default.conf
  ProxyPreserveHost On
  ProxyPass / http://localhost:8080/ nocanon
  ProxyPassReverse / http://localhost:8080/ nocanon
  AllowEncodedSlashes NoDecode


#-- Alias INIT
echo "alias start='docker start guacmysql; docker start guacd; docker start guacamole; vncserver -kill :1; sleep 2; vncserver :1 -geometry 1440x900'" >> $HOME/.bash_aliases
source .bashrc

#-- Serveur X
apt install xfce4 xfce4-goodies
apt install tightvncserver
echo 'startxfce4 &' | tee -a .vnc/xstartup

su - $USER
vncpasswd
vncserver
#ssh -L 5901:localhost:5901 -N -f -l ${USER} $(hostname -i)


#-- Dofus
add-apt-repository "deb https://dl.winehq.org/wine-builds/debian/ stretch main"
wget -nc https://dl.winehq.org/wine-builds/winehq.key
apt-key add winehq.key
rm -f winehq.key
dpkg --add-architecture i386
apt-get update
apt install -y wine-stable winehq-stable
su - $USER
mkdir $HOME/dofus
wget https://download.dofus.com/full/win/ -O $HOME/dofus/dofus.exe
echo "alias dofus='wine /home/jeremi/dofus/dofus.exe'" >> $HOME/.bash_aliases
source .bashrc
