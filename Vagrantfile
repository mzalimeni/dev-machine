# -*- mode: ruby -*-
# vi: set ft=ruby :

def mirror_port(config, port)
  config.vm.network "forwarded_port", guest: port, host: port
end

def share_home(config, dir)
  config.vm.synced_folder File.expand_path("~/#{dir}"), "/home/vagrant/#{dir}", type: "nfs"
end

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.network "private_network", type: "dhcp"

#  mirrored_ports = [6005, 8080, 3000]
#  mirrored_ports.each do |port|
#    mirror_port(config, port)
#  end

  config.vm.synced_folder File.expand_path("~/Development"), "/home/vagrant/Development", type: "nfs"

  [".aws", ".m2", ".lein", ".vim"].each do |dir|
    share_home(config, dir)
  end

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8192"
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
  end
  config.vm.provision "shell", path: "bootstrap.sh"
end
