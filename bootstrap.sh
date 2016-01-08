#!/bin/bash

set -exu

echo "bootstrapping"

UBUNTU_CODENAME=$(lsb_release --codename --short)

MONGO_KEY=7F0CEB10
POSTGRES_KEY_URL=https://www.postgresql.org/media/keys/ACCC4CF8.asc
RABBITMQ_KEY_URL=https://www.rabbitmq.com/rabbitmq-signing-key-public.asc


# Configure system
hostname circle-dev


# Install keys
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv ${MONGO_KEY}
curl --silent ${POSTGRES_KEY_URL} | apt-key add -
curl --silent ${RABBITMQ_KEY_URL} | apt-key add -


# Configure mirrors
apt-get update
apt-get install --yes python-software-properties

add-apt-repository --yes "deb http://ftp.heanet.ie/pub/ubuntu/ ${UBUNTU_CODENAME} main"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME} main restricted universe multiverse"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-updates main restricted universe multiverse"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-backports main restricted universe multiverse"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-security main restricted universe multiverse"


# Add software repos
add-apt-repository --yes "deb http://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/3.0 multiverse"
add-apt-repository --yes "deb http://apt.postgresql.org/pub/repos/apt/ ${UBUNTU_CODENAME}-pgdg main"
add-apt-repository --yes "deb http://www.rabbitmq.com/debian/ testing main"
apt-add-repository --yes ppa:andrei-pozolotin/maven3
add-apt-repository --yes ppa:webupd8team/java


# Set package install defaults
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections


# Install packages
apt-get update
apt-get install --quiet --yes \
  sshfs \
  lxc \
  mongodb-org \
  postgresql-9.4 \
  postgresql-contrib-9.4 \
  redis-server \
  rabbitmq-server \
  oracle-java8-installer \
  oracle-java8-set-default \
  maven3 \
  git \
  socat \
  gnupg2 \
  pinentry-curses

apt-get remove --yes --purge command-not-found
apt-get autoremove --yes --purge

# Install Leingingen
curl --silent --output /usr/local/bin/lein "https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
chmod a+x /usr/local/bin/lein

# Set up the vagrant user's bashrc
BASHRC=/home/vagrant/.bashrc

cat << _EOF >> ${BASHRC}
export PS1="[\u@\[\e[0;35m\]\h\[\e[0m\] \w]$ "

export CIRCLE_ENV=development
export CIRCLE_ROOT=~/Development/circle
export CIRCLE_HOSTNAME=circlehost
export CIRCLE_SCHEME=http
export CIRCLE_HTTP=8080

export LEIN_GPG=/usr/bin/gpg2

if ! pgrep socat > /dev/null 2>&1; then
  mkdir -p /home/vagrant/.gnupg
  rm -f /home/vagrant/.gnupg/S.gpg-agent
  nohup socat -s -d -d -ly "UNIX-LISTEN:/home/vagrant/.gnupg/S.gpg-agent,reuseaddr,fork" "TCP-CONNECT:localhost:60111" &
fi

_EOF

# Configure services
# postgres
sudo -u postgres createuser vagrant -s
sudo -u postgres createuser circle -s

(
cd /etc/postgresql/9.4/main
sudo patch -p1 << _EOF
--- a/pg_hba.conf 2016-01-08 10:17:22.573629737 +0000
+++ b/pg_hba.conf	2016-01-07 18:10:17.143141766 +0000
@@ -88,6 +88,8 @@

 # "local" is for Unix domain socket connections only
 local   all             all                                     peer
+host    circle_test     all             127.0.0.1/32            trust
+host    circle          all             127.0.0.1/32            trust
 # IPv4 local connections:
 host    all             all             127.0.0.1/32            md5
 # IPv6 local connections:
_EOF
)

service postgresql restart

sudo -u vagrant /home/vagrant/Development/circle/script/bootstrap-db.sh

echo "bootstrap finished"
