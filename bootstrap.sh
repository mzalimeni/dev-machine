#!/bin/bash

set -exu

echo "bootstrapping"

UBUNTU_CODENAME=$(lsb_release --codename --short)

MONGO_KEY=7F0CEB10
POSTGRES_KEY_URL=https://www.postgresql.org/media/keys/ACCC4CF8.asc
RABBITMQ_KEY_URL=https://www.rabbitmq.com/rabbitmq-signing-key-public.asc

# Install keys
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv ${MONGO_KEY}
curl --silent ${POSTGRES_KEY_URL} | apt-key add -
curl --silent ${RABBITMQ_KEY_URL} | apt-key add -

apt-get update
apt-get install --yes python-software-properties


# Configure mirrors
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
  git

apt-get remove --yes --purge command-not-found
apt-get autoremove --yes --purge

# Install Leingingen
curl --silent --output /usr/local/bin/lein "https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
chmod a+x /usr/local/bin/lein

# Set up the vagrant user's bashrc
BASHRC=/home/vagrant/.bashrc

echo "export PS1=\"[\u@\[\e[0;32m\]\h\[\e[0m\] \w]$ \"" >> ${BASHRC}
echo "export CIRCLE_ENV=development" >> ${BASHRC}
echo "export CIRCLE_ROOT=/Users/gordon/Development/circle" >> ${BASHRC}
echo "export CIRCLE_NREPL=true" >> ${BASHRC}
echo "export CIRCLE_HOSTNAME=circlehost" >> ${BASHRC}
echo "export CIRCLE_SCHEME=http" >> ${BASHRC}
echo "export CIRCLE_HTTP=8080" >> ${BASHRC}

echo "bootstrap finished"
