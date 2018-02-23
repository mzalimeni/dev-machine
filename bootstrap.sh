#!/bin/bash

set -exu

echo "bootstrapping"

UBUNTU_CODENAME=$(lsb_release --codename --short)

# Configure mirrors
apt-get update
apt-get install --yes python-software-properties

add-apt-repository --yes "deb http://ftp.heanet.ie/pub/ubuntu/ ${UBUNTU_CODENAME} main"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME} main restricted universe multiverse"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-updates main restricted universe multiverse"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-backports main restricted universe multiverse"
add-apt-repository --yes "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-security main restricted universe multiverse"
add-apt-repository ppa:webupd8team/java

# Set package install defaults
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections

# Install packages
apt-get update
apt-get install --quiet --yes \
  apt-transport-https \
  ca-certificates \
  curl \
  git \
  gnupg2 \
  oracle-java8-installer \
  oracle-java8-set-default \
  pinentry-curses \
  socat \
  software-properties-common
apt-get --yes upgrade

# Install docker
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install --yes docker-ce
usermod --append --groups docker vagrant

sudo --user vagrant mkdir /home/vagrant/bin
curl \
  --location \
  --output /home/vagrant/bin/docker-compose \
  "https://github.com/docker/compose/releases/download/1.19.0/docker-compose-$(uname -s)-$(uname -m)"
chown vagrant bin/*

# Docker bash completion
curl \
  --location \
  --output /etc/bash_completion.d/docker \
  "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker"

# Tidy up installed packages
apt-get remove --yes --purge command-not-found
apt-get autoremove --yes --purge

# Install Leingingen
curl --silent --output /usr/local/bin/lein "https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
chmod a+x /usr/local/bin/lein

# Install go
curl --silent --output /tmp/go.tar.gz "https://dl.google.com/go/go1.10.linux-amd64.tar.gz"
sudo --user vagrant tar -C /home/vagrant -xzf /tmp/go.tar.gz
mv /home/vagrant/go /home/vagrant/go1.10
sudo --user vagrant ln -s /home/vagrant/go1.10 /home/vagrant/go

# Set up the vagrant user's bashrc
BASHRC=/home/vagrant/.bashrc

cat << _EOF >> ${BASHRC}
export PS1="[\\u@\\[\\e[0;35m\\]\\h\\[\\e[0m\\] \\w]$ "

export LEIN_GPG=/usr/bin/gpg2

export GOROOT=${HOME}/go
export PATH=${PATH}:${GOROOT}/bin

if ! pgrep socat > /dev/null 2>&1; then
  mkdir -p /home/vagrant/.gnupg
  rm -f /home/vagrant/.gnupg/S.gpg-agent
  nohup socat -s -d -d -ly "UNIX-LISTEN:/home/vagrant/.gnupg/S.gpg-agent,reuseaddr,fork" "TCP-CONNECT:localhost:60111" &
fi

if ! shopt -oq posix; then
  if [ -e ~/.bash_completion ]; then
    . ~/.bash_completion
  fi
fi

if [ -e ~/.iterm2_shell_integration.bash ]; then
  . ~/.iterm2_shell_integration.bash
fi
_EOF

echo "bootstrap finished"
