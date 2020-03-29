# -*- mode: ruby -*-
# vi: set ft=ruby :

def share_home(config, dir)
  config.vm.synced_folder File.expand_path("~/#{dir}"), "/home/vagrant/#{dir}" #, type: "nfs"
end

# Install vagrant-disksize to allow resizing the vagrant box disk.
unless Vagrant.has_plugin?("vagrant-disksize")
  raise  Vagrant::Errors::VagrantError.new, "vagrant-disksize plugin is missing. Please install it using 'vagrant plugin install vagrant-disksize' and rerun 'vagrant up'"
end

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"

  # If under tight constraints, may be possible to get this to 20-30G, depending on the number of services.
  config.disksize.size = '50GB'

  config.vm.network "private_network", type: "dhcp"

  # www-api
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 443

  # api-service, without conflicting w/ local web-ui MFEs
  config.vm.network "forwarded_port", guest: 3000, host: 3009

  # REPLs (pre-exposed - by default, 6005 = www-api, 6008 = WFC)
  config.vm.network "forwarded_port", guest: 6005, host: 6115
  config.vm.network "forwarded_port", guest: 6006, host: 6116
  config.vm.network "forwarded_port", guest: 6007, host: 6117
  config.vm.network "forwarded_port", guest: 6008, host: 6118
  config.vm.network "forwarded_port", guest: 6009, host: 6119

  config.vm.synced_folder File.expand_path("~/Development"), "/home/vagrant/Development" #, type: "nfs"

  [".m2", ".lein", ".vim"].each do |dir|
    share_home(config, dir)
  end

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "8364"
    vb.cpus = 4
    vb.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000]
  end
  config.vm.provision "shell", path: "bootstrap.sh"
end
