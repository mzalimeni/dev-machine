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

killall gpg-agent
eval \$(gpg-agent --daemon --pinentry-program=/usr/bin/pinentry)
_EOF

# Configure services
# postgres
sudo -u postgres createuser vagrant -s
sudo -u postgres createuser circle -s

cat << _EOF >> /etc/postgresql/9.4/main/pg_hba.conf
host  circle_test           all   127.0.0.1/32   trust
host  circle                all   127.0.0.1/32   trust
_EOF

service postgresql restart

sudo -u vagrant /home/vagrant/Development/circle/script/bootstrap-db.sh

echo "bootstrap finished"
